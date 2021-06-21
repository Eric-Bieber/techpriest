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

	class WrathOfMarsBeam : IPreRenderable
	{
        UnitPtr m_unitBeamFx;
		SoundInstance@ m_beamSndI;

		float m_holdDir;
		float m_holdDirNext;

		float m_holdLength;
		float m_holdLengthNext;

		int m_intervalC;
        int m_spins;
		int m_durationC;

        int m_projsShot;
        
        vec2 m_offsetArm;

        int m_index;
		WrathOfMars@ m_skill;

        LaserUpgrade@ m_laserUpgrade;

		array<BeamRayResult2> m_unitsHit;

		UnitPtr m_unitHit;
		bool m_isUnitHit;
		vec2 m_unitHitPos;

        vec2 m_target;

		WrathOfMarsBeam(int index, WrathOfMars@ skill)
		{
			m_index = index;
			@m_skill = skill;
		}

        void stopArmsFiring() {
            auto mechArms = cast<Skills::MechArms>(cast<PlayerBase>(m_skill.m_owner).m_skills[5]);
            if (mechArms !is null) {
                mechArms.m_canFire = false;
            }
        }

        void reActivateArms() {
            auto mechArms = cast<Skills::MechArms>(cast<PlayerBase>(m_skill.m_owner).m_skills[5]);
            if (mechArms !is null) {
                mechArms.m_canFire = true;
            }
        }

        void StartSpin(bool husk, vec2 target)
		{
			if (m_durationC > 0)
				return;

			m_durationC = m_skill.m_duration;
            m_intervalC = m_skill.m_interval;
			m_projsShot = 0;
            m_target = target;
            m_spins = 0;
		}

        vec2 GetArmPosition()
		{
			return xy(m_skill.m_owner.m_unit.GetPosition()) + m_offsetArm;
		}
        
        bool checkLaserUpgrade() {
            auto laserUpgrade = cast<Skills::LaserUpgrade>(cast<PlayerBase>(m_skill.m_owner).m_skills[6]);
            if (laserUpgrade !is null) {
                @m_laserUpgrade = laserUpgrade;
                return true;
            }
            return false;
        }

        vec2 findOffset(int index) {
            auto mechArms = cast<Skills::MechArms>(cast<PlayerBase>(m_skill.m_owner).m_skills[5]);
            if (mechArms !is null) {
                return mechArms.m_arms[index].m_offset;
            }
            return vec2(0,0);
        }
        
		void Update(int dt)
		{
			if (m_durationC <= 0) {
                return;
            }

            if (m_projsShot >= 360) {
                m_spins++;
                m_durationC = m_skill.m_duration;
                m_projsShot = 0;
            }
            
            if (m_spins == m_skill.m_totalSpins) {
                StopBeam();
                return;
            }
				
			m_durationC -= dt;
        
            while (m_durationC <= 0)
			{
                m_durationC += m_skill.m_duration;

                int opposite = 1;
                if (m_index == 1) {
                    opposite = -1;
                }
                m_offsetArm = findOffset(m_index);
                float angle = ((2 * PI / m_skill.m_perRev * opposite) * m_projsShot++) + atan(m_target.y, m_target.x);
                vec2 shootDir = vec2(cos(angle), sin(angle));
                
                HandleBeam(dt, shootDir, false);
            }
		}

		void HandleBeam(int dt, vec2 target, bool husk)
		{
            stopArmsFiring();

			if (husk && !m_skill.m_netHold)
				return;

			m_intervalC -= dt;

			// m_cooldownC = m_skill.m_cooldown;
			// if (!husk)
			// 	m_castingC = m_skill.m_castpoint;

			bool intervalTrigger = (m_intervalC <= 0);
			bool withEffects = (/*!husk &&*/ intervalTrigger);
			if (withEffects)
			{
				m_intervalC += m_skill.m_interval;
			}

			vec2 pos = GetArmPosition();
			vec2 posEndpoint = pos + target * m_skill.m_distance;

			float posDirAngle = atan(target.y, target.x) + PI / 2;
			vec2 posDir = vec2(cos(posDirAngle), sin(posDirAngle)) * m_skill.m_width;

			m_unitsHit.removeRange(0, m_unitsHit.length());
			DoBeamRay(1, pos, posEndpoint);
			DoBeamRay(2, pos - posDir, posEndpoint - posDir);
			DoBeamRay(3, pos + posDir, posEndpoint + posDir);

			vec2 posHit = posEndpoint;
            
			m_isUnitHit = false;
			float length = dist(pos, posHit);
		
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
						length = dist(pos, pos + target * m_skill.m_distance);
						m_unitHitPos = pos + target * length;
					}
					
					m_isUnitHit = true;							
						
					if(res.m_unit.GetCollisionTeam() == 0)
						break;
				}
			}

			float facing = atan(target.y, target.x);
            
			if (!m_unitBeamFx.IsValid())
			{
				if (intervalTrigger)
				{
					m_holdDir = m_holdDirNext = facing;
					m_holdLength = m_holdLengthNext = length;

					vec3 uPos = m_skill.m_owner.m_unit.GetPosition();

					dictionary ePs = {
						{ 'angle', m_holdDir },
						{ 'length', m_holdLength }
					};
                    if (checkLaserUpgrade()) {
                        if (m_laserUpgrade.upgradeNum == 1) {
                            m_unitBeamFx = PlayEffect(m_skill.m_fxLaser_lvl2, pos, ePs);
                        }
                        if (m_laserUpgrade.upgradeNum == 2) {
                            m_unitBeamFx = PlayEffect(m_skill.m_fxLaser_lvl3, pos, ePs);
                        }
                    } else {
                        m_unitBeamFx = PlayEffect(m_skill.m_fx, pos, ePs);
                    }

					if (m_skill.m_sound !is null)
					{
						@m_beamSndI = m_skill.m_sound.PlayTracked(uPos);
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
				m_holdLengthNext = dist(pos, posHit);

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

        void StopBeam() {
            DestroyBeam();

            m_projsShot = 0;
            m_durationC = 0;

			m_isUnitHit = false;
            reActivateArms();
        }

		bool PreRender(int idt)
		{
			if (!m_unitBeamFx.IsValid())
				return true;

			vec3 uPos = m_skill.m_owner.m_unit.GetInterpolatedPosition(idt) + vec3(m_offsetArm.x, m_offsetArm.y, 1);

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

			if (withEffects) {
                ApplyEffects(m_skill.m_effects, m_skill.m_owner, unit, upos, m_holdDir, 1, false);
            }
				
			if (actor !is null && actor.Team != m_skill.m_owner.Team) {
                if (m_laserUpgrade !is null || checkLaserUpgrade()) {
                    for (uint i = 0; i < m_laserUpgrade.m_buffs.length(); i++) {
                        cast<Actor>(unit.GetScriptBehavior()).ApplyBuff(ActorBuff(null, m_laserUpgrade.m_buffs[i], 1.0f, false));
                    }
                }
                return true;
            }	

			return (cast<IDamageTaker>(unit.GetScriptBehavior()) is null);
		}
	}
}
