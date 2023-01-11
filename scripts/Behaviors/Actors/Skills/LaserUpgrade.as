namespace Skills
{
	class LaserUpgrade : Skill
	{
		array<ActorBuffDef@> m_buffs;
        ActorBuffDef@ m_buff;

        int upgradeNum;

		LaserUpgrade(UnitPtr unit, SValue& params)
		{
			super(unit);

            upgradeNum = GetParamInt(unit, params, "upgradeNum");
			int i = 0;
            @m_buff = LoadActorBuff(GetParamString(unit, params, "buff-" + i++, true));
            while (m_buff !is null) {
                m_buffs.insertLast(m_buff);
                @m_buff = LoadActorBuff(GetParamString(unit, params, "buff-" + i++, true));
            }
		}
	}
}
