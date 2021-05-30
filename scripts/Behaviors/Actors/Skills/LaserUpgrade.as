namespace Skills
{
	class LaserUpgrade : Skill
	{
		array<ActorBuffDef@> m_buffs;
        ActorBuffDef@ m_buff;

		LaserUpgrade(UnitPtr unit, SValue& params)
		{
			super(unit);

			int i = 0;
            @m_buff = LoadActorBuff(GetParamString(unit, params, "buff-" + i++, true));
            while (m_buff !is null) {
                m_buffs.insertLast(m_buff);
                @m_buff = LoadActorBuff(GetParamString(unit, params, "buff-" + i++, true));
            }
		}
	}
}
