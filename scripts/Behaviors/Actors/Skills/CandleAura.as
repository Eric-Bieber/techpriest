class CandleAura : ICompositeActorSkill
{
	UnitPtr m_unit;
	CompositeActorBehavior@ m_behavior;

	ActorBuffDef@ m_buff;
	int m_freq;
	int m_freqC;
	int m_range;
	bool m_friendly;

	int m_ttl;
	
	array<ISkillConditional@>@ m_conditionals;

	CandleAura(UnitPtr unit, SValue& params)
	{
		m_unit = unit;
	
		@m_buff = LoadActorBuff(GetParamString(unit, params, "buff", true));
		m_freq = GetParamInt(unit, params, "freq", true, 1000);
		m_range = GetParamInt(unit, params, "range", true, 150);
		m_friendly = GetParamBool(unit, params, "friendly", false, true);

		m_ttl = GetParamInt(unit, params, "ttl", false, -1);
		
		@m_conditionals = LoadSkillConditionals(unit, params);
	}
	
	void Initialize(UnitPtr unit, CompositeActorBehavior& behavior, int id)
	{
		@m_behavior = behavior;
		m_freqC = m_freq;
	}

	void Save(SValueBuilder& builder)
	{
	}

	void Load(SValue@ sval)
	{
	}
	
	void Update(int dt, bool isCasting)
	{
		m_freqC -= dt;
		if (m_freqC <= 0)
		{
			m_freqC += m_freq;
			
			if (!CheckConditionals(m_conditionals, m_behavior))
				return;
			
			array<UnitPtr>@ targets;
			
			if (m_friendly)
					@targets = g_scene.FetchActorsWithTeam(m_behavior.Team, xy(m_unit.GetPosition()), m_range);

			for (uint i = 0; i < targets.length(); i++)
			{
				auto playerCheck = cast<PlayerBase>(targets[i].GetScriptBehavior());
				if (targets[i] == m_unit || playerCheck is null) {
					continue;
				}

				auto actor = cast<Actor>(targets[i].GetScriptBehavior());
				
				if (actor.IsTargetable())
					actor.ApplyBuff(ActorBuff(m_behavior, m_buff, 1.0f, false));
			}
		}

		if (m_ttl > 0 && m_unit.IsValid())
		{
			m_ttl -= dt;
			if (m_ttl <= 0)
				m_unit.Destroy();
		}
	}

	void OnDamaged() {}
	void OnDeath() {}
	void OnCollide(UnitPtr unit, vec2 normal) {}
	void OnSpawn() {}
	void Destroyed() {}
	void NetUseSkill(int stage, SValue@ param) {}
	bool IsCasting() { return false; }
	void CancelSkill() {}
}
