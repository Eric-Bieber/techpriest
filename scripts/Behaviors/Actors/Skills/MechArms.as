namespace Skills
{
	//PhysicsBody@ bdy = m_unit.GetPhysicsBody();
	//bdy.GetLinearVelocity()
	class MechArm
	{
		int m_index;
		MechArms@ m_skill;

		int m_intervalC;

		vec2 m_offset;

		vec2 m_overrideTarget;
		bool m_overrideTargetSet;

		UnitPtr m_target;
		UnitPtr m_beam;

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

		float GetOrbBeamDirection()
		{
			vec2 armPos = GetArmPosition();
			vec2 actorPos = GetTargetPosition();
			vec2 dir = normalize(actorPos - armPos);
			return atan(dir.y, dir.x);
		}

		float GetOrbBeamLength()
		{
			vec2 armPos = GetArmPosition();
			vec2 actorPos = GetTargetPosition();
			return dist(armPos, actorPos);
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

	    vec2 findOffset(float dir) {
			vec2 tempOffset;
			// Left
			if (m_index == 0) {
				// S
				if (dir >= 1.18 && dir < 1.96) {
					tempOffset = vec2(-6, -12);
				}

				// SW
				if (dir >= 1.96 && dir < 2.75) {
					tempOffset = vec2(-6, -12);
				}
				
				// W
				if (dir >= 2.75 || dir < -2.75) {
					tempOffset = vec2(3, -11);
				}

				// NW
				if (dir >= -2.75 && dir < -1.96) {
					tempOffset = vec2(-6, -7);
				}

				// N
				if (dir >= -1.96 && dir < -1.18) {
					tempOffset = vec2(-7, -12);
				}

				// NE
				if (dir >= -1.18 && dir < -.38) {
					tempOffset = vec2(-8, -10);
				}

				// E
				if (dir >= -.38 && dir < .38) {
					tempOffset = vec2(-1, -11);
				}

				// SE
				if (dir >= .38 && dir < 1.18) {
					tempOffset = vec2(-7, -11);
				}
			}
			// Right
			else if (m_index == 1) {
				// S
				if (dir >= 1.18 && dir < 1.96) {
					tempOffset = vec2(6, -12);
				}

				// SW
				if (dir >= 1.96 && dir < 2.75) {
					tempOffset = vec2(8, -9);
				}

				// W
				if (dir >= 2.75 || dir < -2.75) {
					tempOffset = vec2(-1, -11);
				}

				// NW
				if (dir >= -2.75 && dir < -1.96) {
					tempOffset = vec2(7, -10);
				}

				// N
				if (dir >= -1.96 && dir < -1.18) {
					tempOffset = vec2(5, -12);
				}

				// NE
				if (dir >= -1.18 && dir < -.38) {
					tempOffset = vec2(4, -7);
				}

				// E
				if (dir >= -.38 && dir < .38) {
					tempOffset = vec2(-5, -11);
				}

				// SE
				if (dir >= .38 && dir < 1.18) {
					tempOffset = vec2(6, -12);
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
			if (owner !is null)
			{
				Skills::ShootBeam@ skillBeam = null;
				for (uint i = 0; i < owner.m_skills.length(); i++)
				{
					auto s = cast<Skills::ShootBeam>(owner.m_skills[i]);
					if (s is null)
						continue;

					@skillBeam = s;
					break;
				}

				if (skillBeam !is null)
				{
					m_overrideTargetSet = skillBeam.m_isUnitHit;

					if (m_overrideTargetSet)
					{
						m_overrideTarget = skillBeam.m_unitHitPos;
						newTarget = skillBeam.m_unitHit;
					}
				}
			}

			auto input = GetInput();
			auto aimDir = input.AimDir;
			float dir = atan(aimDir.y, aimDir.x);
			
			m_offset = findOffset(dir);

			vec2 armPos = GetArmPosition();

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

			if (!prevTarget.IsValid() && newTarget.IsValid())
				BeamStart();
			else if (prevTarget.IsValid() && !newTarget.IsValid())
				BeamStop();
			else if (m_beam.IsValid())
			{
				m_sndI.SetPosition(xyz(armPos));
				m_beam.SetPosition(xyz(armPos));
				auto beamBehavior = cast<EffectBehavior>(m_beam.GetScriptBehavior());
				if (beamBehavior !is null)
				{
					beamBehavior.SetParam("angle", GetOrbBeamDirection());
					beamBehavior.SetParam("length", GetOrbBeamLength());
				}
			}

			// Maybe apply effects
			m_intervalC -= dt;
			if (m_intervalC <= 0)
			{
				m_intervalC += m_skill.m_effectInterval;
				vec2 targetPos = GetTargetPosition();
				vec2 targetDirection = normalize(targetPos - armPos);
				targetDir = atan(targetDirection.y, targetDirection.x);
				ApplyEffects(m_skill.m_effects, m_skill.m_owner, m_target, targetPos, targetDirection, 1.0f, m_skill.m_owner.IsHusk());
			}
		}

		void BeamStart()
		{
			vec2 armPos = GetArmPosition();

			dictionary ePs = {
				{ 'angle', GetOrbBeamDirection() },
				{ 'length', GetOrbBeamLength() }
			};
			m_beam = PlayEffect(m_skill.m_orbBeamFx, armPos, ePs);

			@m_sndI = m_skill.m_snd.PlayTracked(xyz(armPos));

			auto behavior = cast<EffectBehavior>(m_beam.GetScriptBehavior());
			behavior.m_looping = true;
		}

		void BeamStop()
		{
			if (m_beam.IsValid())
				m_beam.Destroy();

			m_beam = UnitPtr();

			if (m_sndI !is null)
				m_sndI.Stop();
				
			@m_sndI = null;
		}
	}

	class MechArms : Skill
	{
		int m_numArms;

		int m_armRange;
		UnitScene@ m_downFx;
		UnitScene@ m_orbBeamFx;

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

		array<IEffect@>@ m_effects;
		int m_effectInterval;

		array<MechArm@> m_arms;

		MechArms(UnitPtr unit, SValue& params)
		{
			super(unit);

			m_numArms = GetParamInt(unit, params, "num-arms");

			m_armRange = GetParamInt(unit, params, "arm-range");
			@m_downFx = Resources::GetEffect(GetParamString(unit, params, "orb-fx"));
			@m_orbBeamFx = Resources::GetEffect(GetParamString(unit, params, "orb-beam-fx"));

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

			@m_snd = Resources::GetSoundEvent(GetParamString(unit, params, "orb-snd"));

			@m_effects = LoadEffects(unit, params);
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
		
		void OnDestroy() override
		{
			for (uint i = 0; i < m_arms.length(); i++)
				m_arms[i].BeamStop();
		}
	}
}
