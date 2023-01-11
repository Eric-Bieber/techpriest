class ChargeLaserProjectile : RayProjectile
{
	array<IEffect@>@ m_effectsLocal;

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

    Skills::LaserUpgrade@ m_laserUpgrade;

	string m_hitFx;
	SoundEvent@ m_hitSnd;
	SoundInstance@ m_hitsndI;
	
	UnitScene@ m_fxBlockProjectile;

	bool m_fxStart;
	int m_fxCount;
	int m_fxCountC;

	bool m_hitSomething = false;

	SoundEvent@ m_sound;
	SoundInstance@ m_soundI;

	int m_dist;
	int m_distMin;
	int m_distMax;

	int m_damageMin;
	int m_damageMax;	

	vec2 m_offset;

    UnitPtr m_beamFx;
    EffectBehavior@ m_beamFxBehavior;

    string m_fxLaser_lvl2;
    string m_fxLaser_lvl3;

    UnitPtr m_beamFx_fade;
    string m_fxLaser_fade_lvl1;
    string m_fxLaser_fade_lvl2;
    string m_fxLaser_fade_lvl3;
    dictionary m_last_ePs;

    int timeToDie;

    vec2 endPoint;

	float m_intensityLocal;

	ChargeLaserProjectile(UnitPtr unit, SValue& params)
	{
		super(unit, params);
		
		@m_effectsLocal = LoadEffects(unit, params);
		
		m_dist = GetParamInt(unit, params, "dist", false, 50);

		m_damageMin = GetParamInt(unit, params, "damage-min", false, 20);
		m_damageMax = GetParamInt(unit, params, "damage-max", false, 50);

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

        m_fxLaser_lvl2 = GetParamString(unit, params, "fx-lvl2", false);
        m_fxLaser_lvl3 = GetParamString(unit, params, "fx-lvl3", false);

        m_fxLaser_fade_lvl1 = GetParamString(unit, params, "fx-fade-lvl1", false);
        m_fxLaser_fade_lvl2 = GetParamString(unit, params, "fx-fade-lvl2", false);
        m_fxLaser_fade_lvl3 = GetParamString(unit, params, "fx-fade-lvl3", false);

		@m_sound = Resources::GetSoundEvent(GetParamString(unit, params, "snd", false));
	}

	void Initialize(Actor@ owner, vec2 dir, float intensity, bool husk, Actor@ target, uint weapon) override
	{
		StartBeam(dir, husk);
		m_intensityLocal = intensity;

		RayProjectile::Initialize(owner, dir, intensity, false, target, weapon);
	}

	void StartBeam(vec2 dir, bool husk)
	{
		if (m_raysC <= 0)
		{
			m_raysC = m_rays;
            timeToDie = 200;
			m_swingsC = m_swings;
			m_intervalC = 0;
			m_angleStart = atan(dir.y, dir.x) + m_angleOffset;
			m_angle = m_angleStart + randf() * m_angleDelta;
			m_arrHit.removeRange(0, m_arrHit.length());
			m_huskLocal = husk;
			m_fxCountC = m_fxCount;
			
			if (m_fxStart)
				PlaySkillEffect(dir, { { "length", int(m_dist) } });
		}
	}

    bool checkLaserUpgrade() {
        auto laserUpgrade = cast<Skills::LaserUpgrade>(cast<PlayerBase>(m_owner).m_skills[6]);
        if (laserUpgrade !is null) {
            @m_laserUpgrade = laserUpgrade;
            return true;
        }
        return false;
    }

	void Destroyed() override
	{
		// RayProjectile::Destroyed();
		// ApplyEffects(m_destroyEffects, m_owner, m_unit, xy(m_unit.GetPosition()), GetDirection(), m_intensityLocal, m_huskLocal);
	}

	void Collide(UnitPtr unit, vec2 pos, vec2 normal) override
	{
	}

	void Update(int dt) override
	{
        if (m_beamFx.IsValid()) {
            timeToDie -= dt;

            if (timeToDie < 0) {
                PlayFadeEffect();
                
                m_beamFx.Destroy();
                m_beamFx = UnitPtr();

				@m_beamFxBehavior = null;
            }
        }

        if (m_soundI !is null) {
			vec3 uPos = m_owner.m_unit.GetPosition();
			int mod = 0;
			if (uPos.y >= 0) {
				mod = -40;
			} else {
				mod = +40;
			}

			m_soundI.SetPosition(vec3(uPos.x, uPos.y+mod, uPos.z));
		}

		if (m_hitsndI !is null) {
			vec3 uPos = m_owner.m_unit.GetPosition();
			int mod = 0;
			if (uPos.y >= 0) {
				mod = -40;
			} else {
				mod = +40;
			}

			m_hitsndI.SetPosition(vec3(uPos.x, uPos.y+mod, uPos.z));
		}

		if (m_raysC <= 0)
			return;        
		
		m_intervalC -= dt;
		while (m_intervalC <= 0)
		{
			m_intervalC += m_interval;	
			

			bool hitSomething = false;

			vec2 ownerPos = xy(m_unit.GetPosition()) + vec2(0, -Tweak::PlayerCameraHeight);
			vec2 rayDir = vec2(cos(m_angle), sin(m_angle));
			vec2 rayPos = ownerPos + rayDir * int(m_dist);
			array<RaycastResult>@ rayResults;
			
			if (m_rays > 1 && m_angleDelta == 0)
			{
				@rayResults = g_scene.RaycastWide(m_rays, m_rays, ownerPos, rayPos, ~0, m_destroyProjectiles ? RaycastType::Any : RaycastType::Shot);
				m_raysC = 0;
			}
			else
				@rayResults = g_scene.Raycast(ownerPos, rayPos, ~0, m_destroyProjectiles ? RaycastType::Any : RaycastType::Shot);
			
			endPoint = rayPos;

			for (uint i = 0; i < rayResults.length(); i++)
			{
				UnitPtr unit = rayResults[i].FetchUnit(g_scene);
				if (!unit.IsValid())
					continue;

				if (unit == m_unit)
					continue;
                
                if (unit == m_owner.m_unit)
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

				int damage = int(lerp(m_damageMin, m_damageMax, m_intensityLocal));
				SValueBuilder b;
				b.PushDictionary();
				b.PushInteger("magical", int(damage));
				b.PopDictionary();
				m_effectsLocal.insertLast(Damage(m_unit, b.Build()));

				ApplyEffects(m_effectsLocal, m_owner, unit, upos, dir, 1.0, m_huskLocal, 0, 0); // self/team/enemy dmg
                if (m_laserUpgrade !is null || checkLaserUpgrade()) {
                    for (uint j = 0; j < m_laserUpgrade.m_buffs.length(); j++) {
                    	Actor@ actor = cast<Actor>(unit.GetScriptBehavior());
                    	if (actor.Team != m_owner.Team)
                        	actor.ApplyBuff(ActorBuff(null, m_laserUpgrade.m_buffs[j], 1.0f, false));
                    }
                }

				m_effectsLocal.removeLast();

				if (dmgTaker !is null)
					hitSomething = true;
			}

			if (hitSomething) {
				vec3 uPos = m_owner.m_unit.GetPosition();
				int mod = 0;
				if (uPos.y >= 0) {
					mod = -40;
				} else {
					mod = +40;
				}
				@m_hitsndI = m_hitSnd.PlayTracked(vec3(uPos.x, uPos.y+mod, uPos.z));
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

	void PlaySkillEffect(vec2 dir, dictionary ePs = { })
	{	 
		if (!m_huskLocal) {
			// I hate this sound system wtffffffff
			vec3 uPos = m_owner.m_unit.GetPosition();
			int mod = 0;
			if (uPos.y >= 0) {
				mod = -40;
			} else {
				mod = +40;
			}
			@m_soundI = m_sound.PlayTracked(vec3(uPos.x, uPos.y+mod, uPos.z));
		} else if (m_huskLocal) {
			PlaySound3D(m_sound, m_unit.GetPosition());
		}
		

		if (m_fx == "")
			return;

		m_offset = findOffset(m_angle);
		
        float length = dist(xy(m_owner.m_unit.GetPosition()) + m_offset, endPoint);
        ePs = { 
            { 'angle', atan(dir.y, dir.x) },
            { 'length', length },
			{ 'x_offset', m_offset.x },
			{ 'y_offset', m_offset.y }
        };
        m_last_ePs = ePs;
        if (checkLaserUpgrade()) {
            if (m_laserUpgrade.upgradeNum == 1) {
                m_beamFx = PlayEffect(m_fxLaser_lvl2, xy(m_unit.GetPosition()), ePs);
            }
            if (m_laserUpgrade.upgradeNum == 2) {
                m_beamFx = PlayEffect(m_fxLaser_lvl3, xy(m_unit.GetPosition()), ePs);
            }
        } else {
            m_beamFx = PlayEffect(m_fx, xy(m_unit.GetPosition()), ePs);
        }
	
        @m_beamFxBehavior = cast<EffectBehavior>(m_beamFx.GetScriptBehavior());
	}

    void PlayFadeEffect() {
        if (checkLaserUpgrade()) {
            if (m_laserUpgrade.upgradeNum == 1) {
                m_beamFx_fade = PlayEffect(m_fxLaser_fade_lvl2, xy(m_beamFx.GetPosition()) + m_offset, m_last_ePs);
            }
            if (m_laserUpgrade.upgradeNum == 2) {
                m_beamFx_fade = PlayEffect(m_fxLaser_fade_lvl3, xy(m_beamFx.GetPosition()) + m_offset, m_last_ePs);
            }
        } else {
            m_beamFx_fade = PlayEffect(m_fxLaser_fade_lvl1, xy(m_beamFx.GetPosition()) + m_offset, m_last_ePs);
        }
    }
	
	bool HitUnit(UnitPtr unit, vec2 pos, vec2 normal, float selfDmg, bool bounce, bool collide = true) override
	{
		return m_hitSomething;
	}
}
