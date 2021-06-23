namespace Skills
{
	class ChargeLaser : ActiveSkill
	{
		int m_tmCharge;
		int m_tmChargeMax;

		int m_holdFrame;

		UnitProducer@ m_prod;
		string m_fxCharged;
        string m_fxCharged_lvl2;
        string m_fxCharged_lvl3;

		int m_distance;

		bool m_pressOk = false;

		UnitPtr m_chargeFx;
		UnitPtr m_chargeFullFx;

		string m_fxCharge_lvl2;
		string m_fxCharge_lvl3;

		vec2 m_offset;

        float m_length;

		EffectBehavior@ m_chargeFxBehavior;
		EffectBehavior@ m_chargeFxFullBehavior;

        LaserUpgrade@ m_laserUpgrade;

		vec2 m_target;

		ChargeLaser(UnitPtr unit, SValue& params)
		{
			super(unit, params);

			m_tmChargeMax = GetParamInt(unit, params, "charge-max", false, 2000);

			m_holdFrame = GetParamInt(unit, params, "hold-frame", false, -1);

			@m_prod = Resources::GetUnitProducer(GetParamString(unit, params, "unit"));
			m_fxCharged = GetParamString(unit, params, "fx-charged", false, "");
            m_fxCharged_lvl2 = GetParamString(unit, params, "fx-charged_lvl2", false, "");
            m_fxCharged_lvl3 = GetParamString(unit, params, "fx-charged_lvl3", false, "");

            m_fxCharge_lvl2 = GetParamString(unit, params, "fx-charge_lvl2", false, "");
            m_fxCharge_lvl3 = GetParamString(unit, params, "fx-charge_lvl3", false, "");

			m_distance = GetParamInt(unit, params, "distance", false, 200);
		}

		float GetMoveSpeedMul() override
		{
			if (m_isActive && m_pressOk)
				return m_speedMul;
			return 1.0f;
		}
		
		void OnDestroy() override
		{
			Release(m_target);
		}

		vec2 findOffset(float dir) {
			vec2 tempOffset;
			// S
			if (dir >= 1.18 && dir < 1.96) {
				tempOffset = vec2(-3, 9);
			}

			// SW
			if (dir >= 1.96 && dir < 2.75) {
				tempOffset = vec2(-12, 7);
			}
			
			// W
			if (dir >= 2.75 || dir < -2.75) {
				tempOffset = vec2(-13, 0);
			}

			// NW
			if (dir >= -2.75 && dir < -1.96) {
				tempOffset = vec2(-9, -11);
			}

			// N
			if (dir >= -1.96 && dir < -1.18) {
				tempOffset = vec2(4, -16);
			}

			// NE
			if (dir >= -1.18 && dir < -.38) {
				tempOffset = vec2(14, -10);
			}

			// E
			if (dir >= -.38 && dir < .38) {
				tempOffset = vec2(14, 0);
			}

			// SE
			if (dir >= .38 && dir < 1.18) {
				tempOffset = vec2(6, 9);
			}
			return tempOffset;
		}

        bool checkLaserUpgrade() {
            auto laserUpgrade = cast<Skills::LaserUpgrade>(cast<PlayerBase>(m_owner).m_skills[6]);
            if (laserUpgrade !is null) {
                @m_laserUpgrade = laserUpgrade;
                return true;
            }
            return false;
        }
		
		TargetingMode GetTargetingMode(int &out size) override { return TargetingMode::Channeling; }

		void StartChargeEffect()
		{
			if (checkLaserUpgrade()) {
                if (m_laserUpgrade.upgradeNum == 1) {
                    m_chargeFx = PlayEffect(m_fxCharge_lvl2, m_owner.m_unit, dictionary());
                }
                if (m_laserUpgrade.upgradeNum == 2) {
                    m_chargeFx = PlayEffect(m_fxCharge_lvl3, m_owner.m_unit, dictionary());
                }
            } else {
                m_chargeFx = PlayEffect(m_fx, m_owner.m_unit, dictionary());
            }

			@m_chargeFxBehavior = cast<EffectBehavior>(m_chargeFx.GetScriptBehavior());
			m_chargeFxBehavior.m_looping = true;
		}

		void StartFullChargeEffect()
		{
            if (checkLaserUpgrade()) {
                if (m_laserUpgrade.upgradeNum == 1) {
                    m_chargeFullFx = PlayEffect(m_fxCharged_lvl2, m_owner.m_unit, dictionary());
                }
                if (m_laserUpgrade.upgradeNum == 2) {
                    m_chargeFullFx = PlayEffect(m_fxCharged_lvl3, m_owner.m_unit, dictionary());
                }
            } else {
                m_chargeFullFx = PlayEffect(m_fxCharged, m_owner.m_unit, dictionary());
            }

			@m_chargeFxFullBehavior = cast<EffectBehavior>(m_chargeFullFx.GetScriptBehavior());
			m_chargeFxFullBehavior.m_looping = true;
		}

		bool Activate(vec2 target) override
		{
			if (m_isActive)
				return false;

			m_target = target;

			if (ActiveSkill::Activate(target))
			{
				m_tmCharge = 0;
				m_pressOk = true;

				StartChargeEffect();

				return true;
			}

			m_pressOk = false;
			return false;
		}

		void NetActivate(vec2 target) override
		{
			m_tmCharge = 0;

			m_target = target;

			StartChargeEffect();

			ActiveSkill::NetActivate(target);
		}

		void Hold(int dt, vec2 target) override
		{
			if (!m_pressOk)
				return;

			if (m_holdFrame != -1)
				m_owner.m_unit.SetUnitSceneTime(m_holdFrame);

            if (m_tmCharge >= m_tmChargeMax && m_chargeFx.IsValid()) {
                m_chargeFx.Destroy();
            }

			m_cooldownC = m_cooldown;
			m_target = target;			

			if (m_tmCharge < m_tmChargeMax && m_tmCharge + g_wallDelta >= m_tmChargeMax)
			{
				StartFullChargeEffect();

				if (m_chargeFxFullBehavior !is null)
					m_chargeFxFullBehavior.SetParam("angle", atan(m_target.y, m_target.x));
			}
						
			m_tmCharge = min(m_tmChargeMax, m_tmCharge + g_wallDelta);

			ActiveSkill::Hold(dt, target);
		}

		void NetHold(int dt, vec2 target) override
		{
			if (m_holdFrame != -1)
				m_owner.m_unit.SetUnitSceneTime(m_holdFrame);

			m_target = target;

			if (m_tmCharge < m_tmChargeMax && m_tmCharge + g_wallDelta >= m_tmChargeMax)
			{
				StartFullChargeEffect();

				if (m_chargeFxFullBehavior !is null)
					m_chargeFxFullBehavior.SetParam("angle", atan(m_target.y, m_target.x));
			}

			m_tmCharge = min(m_tmChargeMax, m_tmCharge + g_wallDelta);

			ActiveSkill::NetHold(dt, target);
		}

		void Release(vec2 target) override
		{
			ActiveSkill::Release(target);

			if (!m_pressOk)
				return;

			if (m_chargeFx.IsValid())
			{
				m_chargeFx.Destroy();
				m_chargeFx = UnitPtr();

				@m_chargeFxBehavior = null;
			}

			if (m_chargeFullFx.IsValid())
			{
				m_chargeFullFx.Destroy();
				m_chargeFullFx = UnitPtr();

				@m_chargeFxFullBehavior = null;
			}

			float charge = m_tmCharge / float(m_tmChargeMax);
			UnitPtr unit = DoShoot(charge, target);

			m_pressOk = false;
			m_tmCharge = 0;

			(Network::Message("PlayerChargeUnit") << m_skillId << charge << target << unit.GetId()).SendToAll();
			
			
			m_owner.SetUnitScene(m_animation, true);
		}

		void NetRelease(vec2 target) override
		{
			ActiveSkill::NetRelease(target);

			if (m_chargeFx.IsValid())
			{
				m_chargeFx.Destroy();
				m_chargeFx = UnitPtr();

				@m_chargeFxBehavior = null;
			}

			if (m_chargeFullFx.IsValid())
			{
				m_chargeFullFx.Destroy();
				m_chargeFullFx = UnitPtr();

				@m_chargeFxFullBehavior = null;
			}

			m_tmCharge = 0;

			m_owner.SetUnitScene(m_animation, true);
		}

		UnitPtr DoShoot(float charge, vec2 target, int id = 0)
		{
			vec2 shootPos = xy(m_owner.m_unit.GetPosition());
			shootPos += target;

			UnitPtr unit = m_prod.Produce(g_scene, xyz(shootPos), id);

			auto proj = cast<IProjectile>(unit.GetScriptBehavior());
			if (proj !is null)
				proj.Initialize(m_owner, target, charge, false, null, 0);

			return unit;
		}

		void DoUpdate(int dt) override
		{
			if (m_isActive)
				m_animCountdown += dt;

			if (m_chargeFxBehavior !is null) {
                vec2 pos = xy(m_owner.m_unit.GetPosition());
                vec2 posEndpoint = pos + m_target * m_distance;
                auto ray = g_scene.Raycast(pos, posEndpoint, ~0, RaycastType::Shot);

                vec2 posHit = posEndpoint;
                array<BeamRayResult2> m_unitsHit;
                for (uint i = 0; i < ray.length(); i++)
                {
                    UnitPtr unit = ray[i].FetchUnit(g_scene);

                    BeamRayResult2 result;
                    result.m_distSq = int(distsq(pos, ray[i].point));
                    result.m_point = ray[i].point;
                    result.m_unit = unit;
                    m_unitsHit.insertLast(result);
                }

                bool m_isUnitHit = false;
                m_length = dist(pos, posHit);
                m_unitsHit.sortAsc();
                for (uint i = 0; i < m_unitsHit.length(); i++)
                {
                    Skills::BeamRayResult2@ res = m_unitsHit[i];
                    
                    if (checkHitUnit(res.m_unit)) {
                        posHit = res.m_point;

                        if (m_isUnitHit == false)
                        {
                            m_length = dist(pos, posHit);
                        }
                        
                        m_isUnitHit = true;							
                            
                        if(res.m_unit.GetCollisionTeam() == 0)
                            break;
                    }
                }

                m_chargeFxBehavior.SetParam("angle", atan(m_target.y, m_target.x));
                m_chargeFxBehavior.SetParam("length", m_length);
            }
				

			if (m_chargeFxFullBehavior !is null) {
				auto input = GetInput();
				auto aimDir = input.AimDir;
				float dir = atan(aimDir.y, aimDir.x);

				m_offset = findOffset(dir);

				if (m_chargeFxFullBehavior !is null) {
					m_chargeFxFullBehavior.SetParam("angle", atan(m_target.y, m_target.x));
					m_chargeFxFullBehavior.SetParam("x_offset", m_offset.x);
					m_chargeFxFullBehavior.SetParam("y_offset", m_offset.y);
				}
			}
		}
        
        bool checkHitUnit(UnitPtr unit)
		{
			auto actor = cast<Actor>(unit.GetScriptBehavior());

			if (actor !is null && actor.Team != m_owner.Team) {
                return true;
            }	

			return (cast<IDamageTaker>(unit.GetScriptBehavior()) is null);
		}

        bool PreRender(int idt) override
		{
            if (!m_chargeFx.IsValid())
                return true;

            vec3 uPos = m_owner.m_unit.GetInterpolatedPosition(idt);
            m_chargeFx.SetPosition(uPos);

            float mul = idt / 33.0f;
            m_chargeFxBehavior.SetParam("angle", atan(m_target.y, m_target.x));
            m_chargeFxBehavior.SetParam("length", m_length);

            return false;
        } 
	}
}
