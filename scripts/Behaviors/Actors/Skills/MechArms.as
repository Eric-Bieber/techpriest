namespace Skills
{
	class MechArm
	{
		int m_index;
		MechArms@ m_skill;

		int m_intervalC;

		vec2 m_offset;

		vec2 m_overrideTarget;
		bool m_overrideTargetSet;

		UnitPtr m_target;
		UnitPtr m_fire;

		float targetDir;

		SoundInstance@ m_sndI;

		MechArm(int index, MechArms@ skill)
		{
			m_index = index;
			@m_skill = skill;

			m_intervalC = m_skill.m_effectInterval;
		}

		vec2 GetOwnerPosition()
		{
			return xy(m_skill.m_owner.m_unit.GetPosition());
		}

		vec2 GetArmPosition()
		{
			return xy(m_skill.m_owner.m_unit.GetPosition()) + m_offset;
		}

		vec2 GetTargetPosition()
		{
			if (m_overrideTargetSet)
				return m_overrideTarget;
			return xy(m_target.GetPosition());
		}

		void RefreshScene(CustomUnitScene@ scene)
		{
			int layerOffset = 0;
			if (m_offset.y < 0)
				layerOffset = -1;

			auto input = GetInput();
			auto aimDir = input.AimDir;
			float dir = atan(aimDir.y, aimDir.x);

			// Left
			if (m_index == 0) {
				// S
				if (dir >= 1.18 && dir < 1.96) {
					auto sceneTempLeft = GetArmScene(m_skill.S_Left);
					scene.AddScene(sceneTempLeft, 0, vec2(-2, -3), -1, 0);
				}

				// SW
				if (dir >= 1.96 && dir < 2.75) {
					auto sceneTempLeft = GetArmScene(m_skill.SW_Left);
					scene.AddScene(sceneTempLeft, 0, vec2(-2, -6), -1, 0);
				}
				
				// W
				if (dir >= 2.75 || dir < -2.75) {
					auto sceneTempLeft = GetArmScene(m_skill.W_Left);
					scene.AddScene(sceneTempLeft, 0, vec2(3, -3), 1, 0);
				}

				// NW
				if (dir >= -2.75 && dir < -1.96) {
					auto sceneTempLeft = GetArmScene(m_skill.NW_Left);
					scene.AddScene(sceneTempLeft, 0, vec2(0, -2), 1, 0);
				}

				// N
				if (dir >= -1.96 && dir < -1.18) {
					auto sceneTempLeft = GetArmScene(m_skill.N_Left);
					scene.AddScene(sceneTempLeft, 0, vec2(-2, -3), 1, 0);
				}

				// NE
				if (dir >= -1.18 && dir < -.38) {
					auto sceneTempLeft = GetArmScene(m_skill.NE_Left);
					scene.AddScene(sceneTempLeft, 0, vec2(-2, -2), 1, 0);
				}

				// SE
				if (dir >= .38 && dir < 1.18) {
					auto sceneTempLeft = GetArmScene(m_skill.SE_Left);
					scene.AddScene(sceneTempLeft, 0, vec2(0, -3), -1, 0);
				}
			}
			// Right
			else if (m_index == 1) {
				// S
				if (dir >= 1.18 && dir < 1.96) {
					auto sceneTempRight = GetArmScene(m_skill.S_Right);
					scene.AddScene(sceneTempRight, 0, vec2(1, -3), -1, 0);
				}

				// SW
				if (dir >= 1.96 && dir < 2.75) {
					auto sceneTempRight = GetArmScene(m_skill.SW_Right);
					scene.AddScene(sceneTempRight, 0, vec2(2, -2), -1, 0);
				}
				
				// E
				if (dir >= -.38 && dir < .38) {
					auto sceneTempRight = GetArmScene(m_skill.E_Right);
					scene.AddScene(sceneTempRight, 0, vec2(-3, -3), 1, 0);
				}

				// NW
				if (dir >= -2.75 && dir < -1.96) {
					auto sceneTempRight = GetArmScene(m_skill.NW_Right);
					scene.AddScene(sceneTempRight, 0, vec2(1, -2), 1, 0);
				}

				// N
				if (dir >= -1.96 && dir < -1.18) {
					auto sceneTempRight = GetArmScene(m_skill.N_Right);
					scene.AddScene(sceneTempRight, 0, vec2(1, -3), 1, 0);
				}

				// NE
				if (dir >= -1.18 && dir < -.38) {
					auto sceneTempRight = GetArmScene(m_skill.NE_Right);
					scene.AddScene(sceneTempRight, 0, vec2(-1, -2), 1, 0);
				}

				// SE
				if (dir >= .38 && dir < 1.18) {
					auto sceneTempRight = GetArmScene(m_skill.SE_Right);
					scene.AddScene(sceneTempRight, 0, vec2(2, -6), -1, 0);
				}				
			}
		}

        UnitPtr ProduceProjectile(vec2 shootPos, int id = 0)
		{
			return m_skill.m_projectile.Produce(g_scene, xyz(shootPos), id);
		}

	    vec2 findOffset(float dir) {
			vec2 tempOffset;
			// Left
			if (m_index == 0) {
				// S
				if (dir >= 1.18 && dir < 1.96) {
					tempOffset = vec2(-9, -13);
				}

				// SW
				if (dir >= 1.96 && dir < 2.75) {
					tempOffset = vec2(-8, -14);
				}
				
				// W
				if (dir >= 2.75 || dir < -2.75) {
					tempOffset = vec2(-1, -13);
				}

				// NW
				if (dir >= -2.75 && dir < -1.96) {
					tempOffset = vec2(-8, -10);
				}

				// N
				if (dir >= -1.96 && dir < -1.18) {
					tempOffset = vec2(-10, -14);
				}

				// NE
				if (dir >= -1.18 && dir < -.38) {
					tempOffset = vec2(-10, -12);
				}

				// E
				if (dir >= -.38 && dir < .38) {
					tempOffset = vec2(-3, -15);
				}

				// SE
				if (dir >= .38 && dir < 1.18) {
					tempOffset = vec2(-9, -13);
				}
			}
			// Right
			else if (m_index == 1) {
				// S
				if (dir >= 1.18 && dir < 1.96) {
					tempOffset = vec2(4, -13);
				}

				// SW
				if (dir >= 1.96 && dir < 2.75) {
					tempOffset = vec2(4, -12);
				}

				// W
				if (dir >= 2.75 || dir < -2.75) {
					tempOffset = vec2(-3, -15);
				}

				// NW
				if (dir >= -2.75 && dir < -1.96) {
					tempOffset = vec2(2, -13);
				}

				// N
				if (dir >= -1.96 && dir < -1.18) {
					tempOffset = vec2(3, -14);
				}

				// NE
				if (dir >= -1.18 && dir < -.38) {
					tempOffset = vec2(1, -9);
				}

				// E
				if (dir >= -.38 && dir < .38) {
					tempOffset = vec2(-5, -13);
				}

				// SE
				if (dir >= .38 && dir < 1.18) {
					tempOffset = vec2(2, -14);
				}				
			}
			return tempOffset;
		}

		UnitScene@ GetArmScene(AnimString@ anim) {
			string sceneName = anim.GetSceneName(targetDir); 
			auto prod = Resources::GetUnitProducer("players/techpriest/mech_arms.unit");
			return prod.GetUnitScene(sceneName);
		}

		void Update(int dt)
		{
			UnitPtr newTarget;

			// Check if we should override the target
			auto owner = cast<PlayerBase>(m_skill.m_owner);

			auto input = GetInput();
			auto aimDir = input.AimDir;
			float dir = atan(aimDir.y, aimDir.x);
			
			m_offset = findOffset(dir);

			vec2 armPos = GetArmPosition();

            if (m_skill.m_canFire == true) {
                if (!m_overrideTargetSet)
                {
                    // Find closest unit
                    float closestDistance = (m_skill.m_armRange * m_skill.m_armRange) + 1.0f;

                    array<UnitPtr>@ results = g_scene.FetchActorsWithOtherTeam(m_skill.m_owner.Team, armPos, m_skill.m_armRange);
                    for (uint i = 0; i < results.length(); i++)
                    {
                        Actor@ actor = cast<Actor>(results[i].GetScriptBehavior());
                        if (!actor.IsTargetable())
                            continue;

                        bool canSee = true;
                        auto canSeeRes = g_scene.Raycast(armPos, xy(results[i].GetPosition()), ~0, RaycastType::Shot);
                        for (uint j = 0; j < canSeeRes.length(); j++)
                        {
                            UnitPtr canSeeUnit = canSeeRes[j].FetchUnit(g_scene);
                            if (canSeeUnit == results[i])
                                break;

                            auto canSeeActor = cast<Actor>(canSeeUnit.GetScriptBehavior());
                            if (canSeeActor is m_skill.m_owner)
                                continue;

                            canSee = false;
                            break;
                        }
                        if (!canSee)
                            continue;

                        vec2 actorPos = xy(results[i].GetPosition());
                        float d = distsq(armPos, actorPos);
                        if (d < closestDistance)
                        {
                            newTarget = results[i];
                            closestDistance = d;
                        }
                    }
                }

                // Start, stop, or update beam
                UnitPtr prevTarget = m_target;
                m_target = newTarget;

                vec2 targetPos = GetTargetPosition();
                vec2 targetDirection = normalize(targetPos - armPos);
                vec2 shootPos = GetArmPosition();

                // Maybe apply effects
                
                if (inRange()) {
                    m_intervalC -= dt;
                    if (m_intervalC <= 0)
                    {
                        auto proj = ProduceProjectile(shootPos);
                        if (!proj.IsValid())
                            return;
                        
                        auto p = cast<IProjectile>(proj.GetScriptBehavior());
                        if (p is null)
                            return;
                        
                        p.Initialize(m_skill.m_owner, targetDirection, 1.0f, false, m_target, 0);
                        m_fire = PlayEffect(m_skill.m_firefx, armPos);
                        auto behavior = cast<EffectBehavior>(m_fire.GetScriptBehavior());
                        behavior.m_looping = true;

                        auto pp = cast<Projectile>(p);
                        if (pp !is null)
                            pp.m_liveRangeSq *= m_skill.m_armRange;

                        m_intervalC += m_skill.m_effectInterval;
                        targetDir = atan(targetDirection.y, targetDirection.x);
                        if (m_skill.m_buff_stun !is null) {
                            cast<Actor>(m_target.GetScriptBehavior()).ApplyBuff(ActorBuff(null, m_skill.m_buff_stun, 1.0f, false));
                        }
                        if (m_skill.m_buff_fire !is null) {
                            cast<Actor>(m_target.GetScriptBehavior()).ApplyBuff(ActorBuff(null, m_skill.m_buff_fire, 1.0f, false));
                        }
                        @m_sndI = m_skill.m_snd.PlayTracked(xyz(armPos));
                    }
                    m_fire.SetPosition(xyz(armPos));
                } else {
                    m_intervalC = m_skill.m_effectInterval;
                }
            }
		}

        bool inRange() {
            bool inRange = false;
            vec2 targetPos = GetTargetPosition();
            vec2 ownerPos = GetOwnerPosition();
            float distance = dist(ownerPos, targetPos);
            inRange = distance <= 70;
            return inRange;
        }
	}

	class MechArms : Skill
	{
		int m_numArms;

        bool m_canFire = true;

		int m_armRange;
		UnitScene@ m_firefx;
		UnitScene@ m_orbBeamFx;
        UnitProducer@ m_projectile;

		AnimString@ S_Left;
		AnimString@ S_Right;

		AnimString@ SW_Left;
		AnimString@ SW_Right;

		AnimString@ W_Left;

		AnimString@ NW_Left;
		AnimString@ NW_Right;

		AnimString@ N_Left;
		AnimString@ N_Right;

		AnimString@ NE_Left;
		AnimString@ NE_Right;
		
		AnimString@ E_Right;

		AnimString@ SE_Left;
		AnimString@ SE_Right;

		SoundEvent@ m_snd;

		int m_tmNow;

		ActorBuffDef@ m_buff_stun;
        ActorBuffDef@ m_buff_fire;
		int m_effectInterval;

		array<MechArm@> m_arms;

		MechArms(UnitPtr unit, SValue& params)
		{
			super(unit);

			m_numArms = GetParamInt(unit, params, "num-arms");

			m_armRange = GetParamInt(unit, params, "arm-range");
			@m_firefx = Resources::GetEffect(GetParamString(unit, params, "fire-fx"));
            @m_snd = Resources::GetSoundEvent(GetParamString(unit, params, "fire-snd"));
            @m_projectile = Resources::GetUnitProducer(GetParamString(unit, params, "projectile"));

			// South
			@S_Left = AnimString(GetParamString(unit, params, "S_Left"));
			@S_Right = AnimString(GetParamString(unit, params, "S_Right"));

			// South West
			@SW_Left = AnimString(GetParamString(unit, params, "SW_Left"));
			@SW_Right = AnimString(GetParamString(unit, params, "SW_Right"));

			// West
			@W_Left = AnimString(GetParamString(unit, params, "W_Left"));

			// North West
			@NW_Left = AnimString(GetParamString(unit, params, "NW_Left"));
			@NW_Right = AnimString(GetParamString(unit, params, "NW_Right"));

			// North
			@N_Left = AnimString(GetParamString(unit, params, "N_Left"));
			@N_Right = AnimString(GetParamString(unit, params, "N_Right"));

			// North East
			@NE_Left = AnimString(GetParamString(unit, params, "NE_Left"));
			@NE_Right = AnimString(GetParamString(unit, params, "NE_Right"));

			// East
			@E_Right = AnimString(GetParamString(unit, params, "E_Right"));

			// South East
			@SE_Left = AnimString(GetParamString(unit, params, "SE_Left"));
			@SE_Right = AnimString(GetParamString(unit, params, "SE_Right"));

			@m_buff_stun = LoadActorBuff(GetParamString(unit, params, "buff-stun", true));
            @m_buff_fire = LoadActorBuff(GetParamString(unit, params, "buff-fire", true));
			m_effectInterval = GetParamInt(unit, params, "effect-interval");

			for (int i = 0; i < m_numArms; i++)
				m_arms.insertLast(MechArm(m_arms.length(), this));
		}

		void RefreshScene(CustomUnitScene@ scene) override
		{
			for (uint i = 0; i < m_arms.length(); i++)
				m_arms[i].RefreshScene(scene);
		}

		void Update(int dt, bool walking) override
		{
			m_tmNow += dt;

			for (uint i = 0; i < m_arms.length(); i++)
				m_arms[i].Update(dt);
		}
	}
}
