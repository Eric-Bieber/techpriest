namespace Skills
{
	class WrathOfMars : ActiveSkill
	{
		float m_distance;
		float m_width;

		SoundEvent@ m_hitSnd;
		string m_hitFx;

		array<IEffect@>@ m_effects;

		int m_interval;

        int m_totalSpins;

        int m_duration;

        int m_perRev;
        int m_numArms; 

        string m_fxLaser_lvl2;
        string m_fxLaser_lvl3;

        array<WrathOfMarsBeam@> m_beams;

		WrathOfMars(UnitPtr unit, SValue& params)
		{
			super(unit, params);

			m_distance = GetParamFloat(unit, params, "distance", false, 70.0f);
			m_width = GetParamFloat(unit, params, "width", false, 4.0f);

			@m_hitSnd = Resources::GetSoundEvent(GetParamString(unit, params, "hit-snd", false));
			m_hitFx = GetParamString(unit, params, "hit-fx", false);

            m_totalSpins = GetParamInt(unit, params, "spins", false, 1);
            m_duration = GetParamInt(unit, params, "duration", false, 480);
            m_perRev = GetParamInt(unit, params, "per-revolution", false, 16);

            m_fxLaser_lvl2 = GetParamString(unit, params, "fx-lvl2", false);
            m_fxLaser_lvl3 = GetParamString(unit, params, "fx-lvl3", false);

			@m_effects = LoadEffects(unit, params);

			m_interval = GetParamInt(unit, params, "interval", false, 100);
		}
		
		void Initialize(Actor@ owner, ScriptSprite@ icon, uint id) override
		{
			ActiveSkill::Initialize(owner, icon, id);
			PropagateWeaponInformation(m_effects, id + 1);
		}
		
		TargetingMode GetTargetingMode(int &out size) override { return TargetingMode::Channeling; }

		void DoActivate(SValueBuilder@ builder, vec2 target) override
		{
			if (checkNumArms()) {
                for (uint i = 0; i < m_beams.length(); i++)
				    m_beams[i].StartSpin(false, target);;
            }
		}

		void NetDoActivate(SValue@ param, vec2 target) override
		{
            if (checkNumArms()) {
                for (uint i = 0; i < m_beams.length(); i++)
				    m_beams[i].StartSpin(true, target);;
            }
		}

        bool checkNumArms() {
            auto mechArms = cast<Skills::MechArms>(cast<PlayerBase>(m_owner).m_skills[5]);
            if (mechArms !is null) {
                m_numArms = mechArms.m_arms.length();
                if (m_numArms > 0) {
                    if (m_beams.length() < 2) {
                        m_beams.removeRange(0, m_beams.length());
                        for (int i = 0; i < m_numArms; i++)
				            m_beams.insertLast(WrathOfMarsBeam(i, this));
                    }
                    return true;
                }
            }
            return false;
        }
        
		void DoUpdate(int dt) override
		{
            if (m_beams.length() == 0) {
                return;
            }

            for (uint i = 0; i < m_beams.length(); i++)
                m_beams[i].Update(dt);
		}
		
		void OnDestroy() override
		{
            for (uint i = 0; i < m_beams.length(); i++)
				m_beams[i].StopBeam();
		}

		bool PreRender(int idt) override
		{
			for (uint i = 0; i < m_beams.length(); i++)
				m_beams[i].PreRender(idt);
            return false;
		} 
	}
}
