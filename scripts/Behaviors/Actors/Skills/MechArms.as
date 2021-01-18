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

		vec2 GetOrbPosition()
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
			vec2 orbPos = GetOrbPosition();
			vec2 actorPos = GetTargetPosition();
			vec2 dir = normalize(actorPos - orbPos);
			return atan(dir.y, dir.x);
		}

		float GetOrbBeamLength()
		{
			vec2 orbPos = GetOrbPosition();
			vec2 actorPos = GetTargetPosition();
			return dist(orbPos, actorPos);
		}

		void RefreshScene(CustomUnitScene@ scene)
		{
			int layerOffset = 0;
			if (m_offset.y < 0)
				layerOffset = -1;

			auto input = GetInput();
			auto aimDir = input.AimDir;
			float dir = atan(aimDir.y, aimDir.x);

			if (m_index == 0) {
				auto sceneTempLeft = GetArmScene(m_skill.left_arm);
				if (dir > -180 && dir < 0) 
					scene.AddScene(sceneTempLeft, 0, vec2(-2, -3), 1, 0);
				else if (dir > 0 && dir < 180) 
					scene.AddScene(sceneTempLeft, 0, vec2(-2, -3), -1, 0);
			}
			else if (m_index == 1) {
				auto sceneTempRight = GetArmScene(m_skill.right_arm);
				if (dir > -180 && dir < 0) 
					scene.AddScene(sceneTempRight, 0, vec2(1, -3), 1, 0);
				if (dir > 0 && dir < 180) 
					scene.AddScene(sceneTempRight, 0, vec2(1, -3), -1, 0);
			}
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

			// Find offset of orb from player
			float angle = (m_index / float(m_skill.m_numOrbs)) * PI * 2;
			angle += m_skill.m_tmNow / 1000.0f;
			vec2 dir = vec2(cos(angle), sin(angle));

			float distance;
			vec2 ownerPos = GetOwnerPosition();
			auto rayRes = g_scene.Raycast(ownerPos, ownerPos + dir * m_skill.m_orbDistance, ~0, RaycastType::Shot);
			if (rayRes.length() > 0)
				distance = max(0.0f, dist(ownerPos, rayRes[0].point) - 4.0f);
			else
				distance = m_skill.m_orbDistance;
			m_offset = dir * distance;

			vec2 orbPos = GetOrbPosition();

			if (!m_overrideTargetSet)
			{
				// Find closest unit
				float closestDistance = (m_skill.m_orbRange * m_skill.m_orbRange) + 1.0f;

				array<UnitPtr>@ results = g_scene.FetchActorsWithOtherTeam(m_skill.m_owner.Team, orbPos, m_skill.m_orbRange);
				for (uint i = 0; i < results.length(); i++)
				{
					Actor@ actor = cast<Actor>(results[i].GetScriptBehavior());
					if (!actor.IsTargetable())
						continue;

					bool canSee = true;
					auto canSeeRes = g_scene.Raycast(orbPos, xy(results[i].GetPosition()), ~0, RaycastType::Shot);
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
					float d = distsq(orbPos, actorPos);
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
				m_sndI.SetPosition(xyz(orbPos));
				m_beam.SetPosition(xyz(orbPos));
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
				vec2 targetDirection = normalize(targetPos - orbPos);
				targetDir = atan(targetDirection.y, targetDirection.x);
				ApplyEffects(m_skill.m_effects, m_skill.m_owner, m_target, targetPos, targetDirection, 1.0f, m_skill.m_owner.IsHusk());
			}
		}

		void BeamStart()
		{
			vec2 orbPos = GetOrbPosition();

			dictionary ePs = {
				{ 'angle', GetOrbBeamDirection() },
				{ 'length', GetOrbBeamLength() }
			};
			m_beam = PlayEffect(m_skill.m_orbBeamFx, orbPos, ePs);

			@m_sndI = m_skill.m_snd.PlayTracked(xyz(orbPos));

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
		int m_numOrbs;

		float m_orbDistance;
		int m_orbRange;
		UnitScene@ m_downFx;
		UnitScene@ m_orbBeamFx;

		AnimString@ left_arm;
		AnimString@ right_arm;

		SoundEvent@ m_snd;

		int m_tmNow;

		array<IEffect@>@ m_effects;
		int m_effectInterval;

		array<MechArm@> m_orbs;

		MechArms(UnitPtr unit, SValue& params)
		{
			super(unit);

			m_numOrbs = GetParamInt(unit, params, "num-orbs");

			m_orbDistance = GetParamFloat(unit, params, "orb-distance");
			m_orbRange = GetParamInt(unit, params, "orb-range");
			@m_downFx = Resources::GetEffect(GetParamString(unit, params, "orb-fx"));
			@m_orbBeamFx = Resources::GetEffect(GetParamString(unit, params, "orb-beam-fx"));

			@left_arm = AnimString(GetParamString(unit, params, "left-arm-anim"));
			@right_arm = AnimString(GetParamString(unit, params, "right-arm-anim"));

			@m_snd = Resources::GetSoundEvent(GetParamString(unit, params, "orb-snd"));

			@m_effects = LoadEffects(unit, params);
			m_effectInterval = GetParamInt(unit, params, "effect-interval");

			for (int i = 0; i < m_numOrbs; i++)
				m_orbs.insertLast(MechArm(m_orbs.length(), this));
		}

		void RefreshScene(CustomUnitScene@ scene) override
		{
			for (uint i = 0; i < m_orbs.length(); i++)
				m_orbs[i].RefreshScene(scene);
		}

		void Update(int dt, bool walking) override
		{
			m_tmNow += dt;
			auto input = GetInput();
			auto aimDir = input.AimDir;
			print(aimDir);

			for (uint i = 0; i < m_orbs.length(); i++)
				m_orbs[i].Update(dt);
		}
		
		void OnDestroy() override
		{
			for (uint i = 0; i < m_orbs.length(); i++)
				m_orbs[i].BeamStop();
		}
	}
}
