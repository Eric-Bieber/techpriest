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

        float m_dir;

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

				@m_soundHoldI = m_soundHold.PlayTracked(m_owner.m_unit.GetPosition());

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

				if (m_chargeFxFullBehavior !is null) {
					m_chargeFxFullBehavior.SetParam("angle", atan(m_target.y, m_target.x));
				}
			}
						
			m_tmCharge = min(m_tmChargeMax, m_tmCharge + g_wallDelta);

			//ActiveSkill::Hold(dt, target);
		}

		void NetHold(int dt, vec2 target) override
		{
			if (m_holdFrame != -1)
				m_owner.m_unit.SetUnitSceneTime(m_holdFrame);

			m_owner.SetUnitScene(m_animation, true);

			m_target = target;

			if (m_tmCharge >= m_tmChargeMax && m_chargeFx.IsValid()) {
                m_chargeFx.Destroy();
            }

			if (m_tmCharge < m_tmChargeMax && m_tmCharge + g_wallDelta >= m_tmChargeMax)
			{
				StartFullChargeEffect();

				if (m_chargeFxFullBehavior !is null) {
					m_chargeFxFullBehavior.SetParam("angle", atan(m_target.y, m_target.x));
				}
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

			(Network::Message("PlayerChargeLaser") << m_skillId << charge << target << unit.GetId()).SendToAll();
			
			m_owner.SetUnitScene(m_animation, false);			
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

			m_owner.SetUnitScene(m_animation, false);
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

			if (m_soundHoldI !is null) {
				vec3 uPos = m_owner.m_unit.GetPosition();
				int mod = 0;
				if (uPos.y >= 0) {
					mod = -40;
				} else {
					mod = +40;
				}

				m_soundHoldI.SetPosition(vec3(uPos.x, uPos.y+mod, uPos.z));
			}

			if (m_chargeFxBehavior !is null) {
                m_chargeFxBehavior.SetParam("angle", atan(m_target.y, m_target.x));
            }
				
			if (m_chargeFxFullBehavior !is null) {
				m_dir = atan(m_target.y, m_target.x);

				m_offset = findOffset(m_dir);
				m_chargeFxFullBehavior.SetParam("angle", atan(m_target.y, m_target.x));
				m_chargeFxFullBehavior.SetParam("x_offset", m_offset.x);
				m_chargeFxFullBehavior.SetParam("y_offset", m_offset.y);
			}
		}
	}
}
