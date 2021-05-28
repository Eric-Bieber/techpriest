namespace Skills
{
	class BeamRayResult2
	{
		int m_distSq;
		vec2 m_point;
		UnitPtr m_unit;

		int opCmp(const BeamRayResult2 &other)
		{
			if (m_distSq < other.m_distSq)
				return -1;
			else if (m_distSq > other.m_distSq)
				return 1;
			return 0;
		}
	}

	class MyShootBeam : ActiveSkill
	{
		UnitPtr m_unitBeamFx;
		SoundInstance@ m_beamSndI;

		float m_distance;
		float m_width;

		SoundEvent@ m_hitSnd;
		string m_hitFx;

		float m_holdDir;
		float m_holdDirNext;

		float m_holdLength;
		float m_holdLengthNext;

		array<IEffect@>@ m_effects;
		array<IEffect@>@ m_effectsTeam;

		int m_interval;
		int m_intervalC;

        int m_totalSpins;
        int m_spins;

        int m_duration;
		int m_durationC;

        int m_perRev;
        int m_projsShot;
        
        vec2 m_offsetArm;
        int m_numArms; 

        bool m_canUseAbility = false;

		array<BeamRayResult2> m_unitsHit;

		UnitPtr m_unitHit;
		bool m_isUnitHit;
		vec2 m_unitHitPos;

        vec2 m_target;

		MyShootBeam(UnitPtr unit, SValue& params)
		{
			super(unit, params);

			m_distance = GetParamFloat(unit, params, "distance", false, 70.0f);
			m_width = GetParamFloat(unit, params, "width", false, 4.0f);

			@m_hitSnd = Resources::GetSoundEvent(GetParamString(unit, params, "hit-snd", false));
			m_hitFx = GetParamString(unit, params, "hit-fx", false);
            m_totalSpins = GetParamInt(unit, params, "spins", false, 1);
            m_duration = GetParamInt(unit, params, "duration", false, 480);
            m_perRev = GetParamInt(unit, params, "per-revolution", false, 16);

			@m_effects = LoadEffects(unit, params);
			@m_effectsTeam = LoadEffects(unit, params, "team-");

			m_interval = GetParamInt(unit, params, "interval", false, 100);
		}
		
		void Initialize(Actor@ owner, ScriptSprite@ icon, uint id) override
		{
			ActiveSkill::Initialize(owner, icon, id);
			PropagateWeaponInformation(m_effects, id + 1);
			PropagateWeaponInformation(m_effectsTeam, id + 1);
		}

        void stopArmsFiring() {
            auto mechArms = cast<Skills::MechArms>(cast<PlayerBase>(m_owner).m_skills[6]);
            if (mechArms !is null) {
                mechArms.m_canFire = false;
            }
        }

        void reActivateArms() {
            auto mechArms = cast<Skills::MechArms>(cast<PlayerBase>(m_owner).m_skills[6]);
            if (mechArms !is null) {
                mechArms.m_canFire = true;
            }
        }
		
		TargetingMode GetTargetingMode(int &out size) override { return TargetingMode::Channeling; }

		void DoActivate(SValueBuilder@ builder, vec2 target) override
		{
			if (checkNumArms()) {
                StartSpin(false, target);
            }
		}

		void NetDoActivate(SValue@ param, vec2 target) override
		{
            if (checkNumArms()) {
                StartSpin(true, target);
            }
		}

        void StartSpin(bool husk, vec2 target)
		{
			if (m_durationC > 0)
				return;

			m_durationC = m_duration;
			m_animCountdown = m_duration - m_castpoint;
			m_projsShot = 0;
            m_target = target;
            m_spins = 0;
		}

        vec2 GetArmPosition()
		{
			return xy(m_owner.m_unit.GetPosition()) + m_offsetArm;
		}

        vec2 findOffset(int index) {
            auto mechArms = cast<Skills::MechArms>(cast<PlayerBase>(m_owner).m_skills[6]);
            if (mechArms !is null) {
                return mechArms.m_arms[index].m_offset;
            }
            return vec2(0,0);
        }

        bool checkNumArms() {
            auto mechArms = cast<Skills::MechArms>(cast<PlayerBase>(m_owner).m_skills[6]);
            if (mechArms !is null) {
                m_numArms = mechArms.m_arms.length();
                if (m_numArms > 0) {
                    return true;
                }
            }
            return false;
        }
        
		void DoUpdate(int dt) override
		{
			if (m_durationC <= 0) {
                return;
            }

            if (m_projsShot >= 360) {
                m_spins++;
                m_durationC = m_duration;
                m_projsShot = 0;
            }
            
            if (m_spins == m_totalSpins) {
                StopBeam();
                return;
            }
				
			m_durationC -= dt;
        
            while (m_durationC <= 0)
			{
                m_durationC += m_duration;

                m_offsetArm = findOffset(0);
                float angle = ((2 * PI / m_perRev) * m_projsShot++) + atan(m_target.y, m_target.x);
                vec2 shootDir = vec2(cos(angle), sin(angle));
                
                HandleBeam(dt, shootDir, false);

                if (m_numArms > 1) {
                    m_offsetArm = findOffset(1);
                    angle = ((2 * PI / m_perRev) * (m_projsShot - 1)) + atan(m_target.y, m_target.x);
                    shootDir = vec2(cos(angle), sin(angle));
                    
                    HandleBeam(dt, shootDir, false);
                }
            }
		}

		void HandleBeam(int dt, vec2 target, bool husk)
		{
            stopArmsFiring();

			if (husk && !m_netHold)
				return;

			m_intervalC -= dt;

			m_cooldownC = m_cooldown;
			if (!husk)
				m_castingC = m_castpoint;

			bool intervalTrigger = (m_intervalC <= 0);
			bool withEffects = (/*!husk &&*/ intervalTrigger);
			if (withEffects)
			{
				m_intervalC += m_interval;
				if (!m_owner.SpendCost(m_costMana, m_costStamina, m_costHealth))
				{
					Release(target);
					return;
				}
			}

			vec2 pos = GetArmPosition();
			vec2 posEndpoint = pos + target * m_distance;

			float posDirAngle = atan(target.y, target.x) + PI / 2;
			vec2 posDir = vec2(cos(posDirAngle), sin(posDirAngle)) * m_width;

			m_unitsHit.removeRange(0, m_unitsHit.length());
			DoBeamRay(1, pos, posEndpoint);
			// DoBeamRay(2, pos - posDir, posEndpoint - posDir);
			// DoBeamRay(3, pos + posDir, posEndpoint + posDir);

			vec2 posHit = posEndpoint;

			m_isUnitHit = false;
			float length;
		
			m_unitsHit.sortAsc();
			for (uint i = 0; i < m_unitsHit.length(); i++)
			{
				BeamRayResult2@ res = m_unitsHit[i];
				if (HandleHitUnit(res.m_unit, withEffects))
				{
					posHit = res.m_point;

					if (m_isUnitHit == false)
					{
						m_unitHit = res.m_unit;
						length = dist(pos, pos + target * m_distance);
						m_unitHitPos = pos + target * length;
					}
					
					m_isUnitHit = true;							
						
					if(res.m_unit.GetCollisionTeam() == 0)
						break;
				}
				

			}

			float facing = atan(target.y, target.x);
			length = dist(pos, posHit);

			if (!m_unitBeamFx.IsValid())
			{
				if (intervalTrigger)
				{
					m_holdDir = m_holdDirNext = facing;
					m_holdLength = m_holdLengthNext = length;

					vec3 uPos = m_owner.m_unit.GetPosition();

					dictionary ePs = {
						{ 'angle', m_holdDir },
						{ 'length', m_holdLength }
					};
					m_unitBeamFx = PlayEffect(m_fx, pos, ePs);

					if (m_sound !is null)
					{
						@m_beamSndI = m_sound.PlayTracked(uPos);
						m_beamSndI.SetLooped(true);
					}

					auto behavior = cast<EffectBehavior>(m_unitBeamFx.GetScriptBehavior());
					behavior.m_looping = true;

					m_preRenderables.insertLast(this);
				}
			}
			else
			{
				m_holdDir = m_holdDirNext;
				m_holdLength = m_holdLengthNext;

				m_holdDirNext = facing;
				m_holdLengthNext = dist(pos, pos + target * m_distance);

				// deal with 360 to 0 wrapping
				if (abs(m_holdDirNext - m_holdDir) > PI / 2.0)
					m_holdDir = m_holdDirNext;
			}
		}

		void DestroyBeam()
		{
			if (!m_unitBeamFx.IsValid())
				return;

			m_unitBeamFx.Destroy();
			m_unitBeamFx = UnitPtr();

			if (m_beamSndI !is null)
			{
				m_beamSndI.Stop();
				@m_beamSndI = null;
			}
		}
		
		void OnDestroy() override
		{
			DestroyBeam();
		}

        void StopBeam() {
            DestroyBeam();

            m_projsShot = 0;
            m_durationC = 0;

			m_isUnitHit = false;
            reActivateArms();
        }

		bool PreRender(int idt) override
		{
			if (!m_unitBeamFx.IsValid())
				return true;

			vec3 uPos = m_owner.m_unit.GetInterpolatedPosition(idt) + vec3(m_offsetArm.x, m_offsetArm.y, 1);

			m_beamSndI.SetPosition(uPos);
			m_unitBeamFx.SetPosition(uPos);

			auto behavior = cast<EffectBehavior>(m_unitBeamFx.GetScriptBehavior());
			if (behavior is null)
				return true;

			float mul = idt / 33.0f;
			behavior.SetParam("angle", lerp(m_holdDir, m_holdDirNext, mul));
			behavior.SetParam("length", lerp(m_holdLength, m_holdLengthNext, mul));

			return false;
		} 

		void DoBeamRay(int id, vec2 pos, vec2 posEndpoint)
		{
			auto ray = g_scene.Raycast(pos, posEndpoint, ~0, RaycastType::Shot);
			for (uint i = 0; i < ray.length(); i++)
			{
				UnitPtr unit = ray[i].FetchUnit(g_scene);

				BeamRayResult2 result;
				result.m_distSq = int(distsq(pos, ray[i].point));
				result.m_point = ray[i].point;
				result.m_unit = unit;
				m_unitsHit.insertLast(result);
			}
		}

		bool HandleHitUnit(UnitPtr unit, bool withEffects)
		{
			vec2 upos = xy(unit.GetPosition());

			auto actor = cast<Actor>(unit.GetScriptBehavior());

			if (withEffects)
				ApplyEffects(m_effects, m_owner, unit, upos, m_holdDir, 1, false);

			if (actor !is null && actor.Team != m_owner.Team)
				return true;

			return (cast<IDamageTaker>(unit.GetScriptBehavior()) is null);
		}
	}
}
