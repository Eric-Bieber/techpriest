namespace Skills
{
	class DropDevice : ActiveSkill
	{
		UnitProducer@ m_prod;
		bool m_needNetSync;

		uint m_maxCount;
		bool m_removeOldest;

		float m_distance;

        bool active = false;
        bool spawned = false;

        int m_timer;
        int origTimer;

        vec2 m_target;
        vec3 m_unitPos;

		array<UnitPtr> m_units;

		DropDevice(UnitPtr unit, SValue& params)
		{
			super(unit, params);

			@m_prod = Resources::GetUnitProducer(GetParamString(unit, params, "unit"));
			m_needNetSync = !IsNetsyncedExistance(m_prod.GetNetSyncMode());

			m_maxCount = GetParamInt(unit, params, "max-count");
			m_removeOldest = GetParamBool(unit, params, "remove-oldest", false);

			m_distance = GetParamFloat(unit, params, "offset", false, 0.0f);

            origTimer = GetParamInt(unit, params, "wait", false, 500);
		}

		TargetingMode GetTargetingMode(int &out size) override { return TargetingMode::TargetAOE; }

		bool Activate(vec2 target) override
		{
			if (!m_removeOldest && m_units.length() >= m_maxCount)
				return false;

			return ActiveSkill::Activate(target);
		}

		bool NeedNetParams() override { return true; }

		void DoActivate(SValueBuilder@ builder, vec2 target) override
		{
			vec3 unitPos = m_owner.m_unit.GetPosition() + xyz(target * m_distance);
			unitPos.z = 0;
            m_unitPos = unitPos;
			builder.PushVector3(unitPos);

            active = true;
            m_target = target;
            m_timer = origTimer;
            
            PlaySkillEffect(target);
		}

		void NetDoActivate(SValue@ param, vec2 target) override
		{
			if (!m_needNetSync && !Network::IsServer())
			{
				PlaySkillEffect(target);
				return;
			}
            PlaySkillEffect(target);

            active = true;
            m_target = target;
            m_timer = origTimer;

			vec3 unitPos = param.GetVector3();
            m_unitPos = unitPos;
		}

		void DoUpdate(int dt) override
		{
            if (active) {
                m_timer -= dt;
                if (m_timer < 0 && !spawned) {
                    SpawnUnit(m_unitPos, m_target);
                    spawned = true;
                }
            }

			for (int i = m_units.length() - 1; i >= 0; i--)
			{
				if (m_units[i].IsDestroyed()) {
                    m_units.removeAt(i);
                    spawned = false;
                    m_timer = origTimer;
                    active = false;
                }
					
			}
		}

		UnitPtr SpawnUnit(vec3 pos, vec2 target)
		{
			UnitPtr unit = m_prod.Produce(g_scene, pos);

			auto ownedUnit = cast<IOwnedUnit>(unit.GetScriptBehavior());
			if (ownedUnit !is null)
			{
				ownedUnit.Initialize(m_owner, 1.0f, false, m_skillId + 1);

				if (!m_needNetSync && Network::IsServer())
					(Network::Message("SetOwnedUnit") << unit << m_owner.m_unit << 1.0f).SendToAll();
			}

			m_units.insertLast(unit);

			if (m_removeOldest && m_units.length() > m_maxCount)
			{
				UnitPtr unitToRemove = m_units[0];
				m_units.removeAt(0);
				unitToRemove.Destroy();
			}

			return unit;
		}
	}
}
