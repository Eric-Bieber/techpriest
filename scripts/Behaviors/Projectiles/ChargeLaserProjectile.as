class ChargeLaserProjectile : RayProjectile
{
	array<IEffect@>@ m_effectsLocal;

	int m_dist;
	float m_distMul;
	int m_rays;
	float m_angleDelta;
	float m_angleOffset;
	int m_interval;
	bool m_huskLocal;
	int m_swings;
	bool m_destroyProjectiles;

	int m_raysC;
	int m_intervalC;
	int m_swingsC;
	float m_angle;
	float m_angleStart;
	array<UnitPtr> m_arrHit;

	string m_hitFx;
	SoundEvent@ m_hitSnd;
	
	UnitScene@ m_fxBlockProjectile;

	bool m_fxStart;
	int m_fxCount;
	int m_fxCountC;

	bool m_hitSomething = false;

	SoundEvent@ m_sound;
	

	ChargeLaserProjectile(UnitPtr unit, SValue& params)
	{
		super(unit, params);
		
		@m_effectsLocal = LoadEffects(unit, params);
		
		m_dist = GetParamInt(unit, params, "dist", false, 10);
		m_distMul = 1.0f;
		m_rays = GetParamInt(unit, params, "rays", false, 4);

		int arc = GetParamInt(unit, params, "arc", false, 45);
		m_angleDelta = (arc * PI / 180) / max(1, m_rays - 1);
		m_angleOffset = GetParamInt(unit, params, "angleoffset", false, -arc / 2) * PI / 180.f;
		m_swings = GetParamInt(unit, params, "swings", false, 1);
		m_interval = GetParamInt(unit, params, "duration", false, 150) / m_rays / m_swings - 1;
		
		m_hitFx = GetParamString(unit, params, "hit-fx", false);
		@m_hitSnd = Resources::GetSoundEvent(GetParamString(unit, params, "hit-snd", false));
		
		m_destroyProjectiles = GetParamBool(unit, params, "destroy-projectiles", false, false);
		@m_fxBlockProjectile = Resources::GetEffect("effects/players/block_projectile.effect");

		m_fxStart = GetParamBool(unit, params, "play-fx-start", false, true);
		m_fxCount = GetParamInt(unit, params, "play-fx-count", false, -1);

		@m_sound = Resources::GetSoundEvent(GetParamString(unit, params, "snd", false));
	}

	void Initialize(Actor@ owner, vec2 dir, float intensity, bool husk, Actor@ target, uint weapon) override
	{
		StartBeam(dir, false);
		//StartBeam(target, true);
	}

	void StartBeam(vec2 dir, bool husk)
	{
		if (m_raysC <= 0)
		{
			m_raysC = m_rays;
			m_swingsC = m_swings;
			m_intervalC = 0;
			m_angleStart = atan(dir.y, dir.x) + m_angleOffset;
			m_angle = m_angleStart + randf() * m_angleDelta;
			m_arrHit.removeRange(0, m_arrHit.length());
			m_huskLocal = husk;
			m_fxCountC = m_fxCount;
			
			if (m_fxStart)
				PlaySkillEffect(dir, { { "length", int(m_dist * m_distMul) } });
		}
	}

	void Destroyed() override
	{
		// RayProjectile::Destroyed();
		// ApplyEffects(m_destroyEffects, m_owner, m_unit, xy(m_unit.GetPosition()), GetDirection(), m_intensity, m_huskLocal);
	}

	void Collide(UnitPtr unit, vec2 pos, vec2 normal) override
	{
	}

	void Collide(UnitPtr unit, vec2 pos, vec2 normal, Fixture@ fxSelf, Fixture@ fxOther)
	{
		// if (fxSelf.GetIndex() == 0)
		// 	HitUnit(unit, pos, normal, m_selfDmg, true);
		// else
		//HitUnit(unit, pos, normal, m_selfDmg, false, false);
	}

	void Update(int dt) override
	{
		if (m_raysC <= 0)
			return;

		
		m_intervalC -= dt;
		while (m_intervalC <= 0)
		{
			m_intervalC += m_interval;	
			

			bool hitSomething = false;

			vec2 ownerPos = xy(m_unit.GetPosition()) + vec2(0, -Tweak::PlayerCameraHeight);
			vec2 rayDir = vec2(cos(m_angle), sin(m_angle));
			vec2 rayPos = ownerPos + rayDir * int(m_dist * m_distMul);
			array<RaycastResult>@ rayResults;
			
			if (m_rays > 1 && m_angleDelta == 0)
			{
				@rayResults = g_scene.RaycastWide(m_rays, m_rays, ownerPos, rayPos, ~0, m_destroyProjectiles ? RaycastType::Any : RaycastType::Shot);
				m_raysC = 0;
			}
			else
				@rayResults = g_scene.Raycast(ownerPos, rayPos, ~0, m_destroyProjectiles ? RaycastType::Any : RaycastType::Shot);
			
			vec2 endPoint = rayPos;

			for (uint i = 0; i < rayResults.length(); i++)
			{
				UnitPtr unit = rayResults[i].FetchUnit(g_scene);
				if (!unit.IsValid())
					continue;

				if (unit == m_unit)
					continue;

				auto dmgTaker = cast<IDamageTaker>(unit.GetScriptBehavior());
				if (dmgTaker !is null && dmgTaker.ShootThrough(m_owner, rayPos, rayDir))
					continue;

				auto proj = cast<IProjectile>(unit.GetScriptBehavior());
				if (proj is null)
				{
					if (m_destroyProjectiles && !rayResults[i].fixture.RaycastTypeTest(RaycastType::Shot))
						continue;

					if (dmgTaker is null)// || dmgTaker.Impenetrable())
					{
						endPoint = rayResults[i].point;
						break;
					}
				}

				bool alreadyHit = false;
				for (uint j = 0; j < m_arrHit.length(); j++)
				{
					if (m_arrHit[j] == unit)
					{
						alreadyHit = true;
						break;
					}
				}
				if (alreadyHit)
					continue;

				m_arrHit.insertLast(unit);

				vec2 upos = xy(unit.GetPosition());
				
				if (proj !is null)
				{
					if (m_destroyProjectiles && proj.IsBlockable() && proj.Team != m_owner.Team)
					{
						PlayEffect(m_fxBlockProjectile, upos);
						unit.Destroy();
					}
					continue;
				}
				
				vec2 dir = normalize(xy(m_unit.GetPosition()) - upos);
				ApplyEffects(m_effectsLocal, m_owner, unit, upos, dir, 1.0, m_huskLocal, 0, 0); // self/team/enemy dmg

				dictionary ePs = { { 'angle', m_angle } };
				PlayEffect(m_hitFx, rayResults[i].point, ePs);

				if (dmgTaker !is null)
					hitSomething = true;
			}

			if (hitSomething) {
				PlaySound3D(m_hitSnd, m_unit.GetPosition());
				m_hitSomething = true;
			}
					
			if (--m_raysC <= 0)
			{
				m_arrHit.removeRange(0, m_arrHit.length());
				
				if (--m_swingsC > 0)
				{
					m_raysC = m_rays;
					m_intervalC = 0;
					m_angle = m_angleStart + randf() * m_angleDelta;

					PlaySkillEffect(vec2(cos(m_angle - m_angleOffset), sin(m_angle - m_angleOffset)), { { "length", dist(ownerPos, endPoint) } });
				}
				else if (--m_fxCountC >= 0)
					PlaySkillEffect(vec2(cos(m_angle - m_angleOffset), sin(m_angle - m_angleOffset)), { { "length", dist(ownerPos, endPoint) } });
				
				return;
			}
			
			m_angle += m_angleDelta;
		}
	}

	void PlaySkillEffect(vec2 dir, dictionary ePs = { })
	{
		PlaySound3D(m_sound, m_unit.GetPosition());
	
		if (m_fx == "")
			return;
		
		ePs["angle"] = atan(dir.y, dir.x);
		PlayEffect(m_fx, xy(m_unit.GetPosition()), ePs);
	}
	
	bool HitUnit(UnitPtr unit, vec2 pos, vec2 normal, float selfDmg, bool bounce, bool collide = true) override
	{
		// if (!unit.IsValid())
		// 	return true;

		// auto dt = cast<IDamageTaker>(unit.GetScriptBehavior());
		// if (dt !is null && dt.Impenetrable())
		// {
		// 	m_unit.Destroy();
		// 	return false;
		// }
		
		//return RayProjectile::HitUnit(unit, pos, normal, selfDmg, bounce, collide);
		return m_hitSomething;
	}
}
