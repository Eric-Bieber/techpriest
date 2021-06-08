class LaserProjectile : RayProjectile
{
	int m_bounceTTLAdd;
	uint m_lastBounceTime;

    Skills::LaserUpgrade@ m_laserUpgrade;
    AnimString@ m_laser_lvl2;
    AnimString@ m_laser_lvl3;

	LaserProjectile(UnitPtr unit, SValue& params)
	{
		super(unit, params);

		m_bounceTTLAdd = GetParamInt(unit, params, "bounce-ttl-add", false, 0);
        @m_laser_lvl2 = AnimString(GetParamString(unit, params, "anim-lvl2"));
        @m_laser_lvl3 = AnimString(GetParamString(unit, params, "anim-lvl3"));
	}

    void Collide(UnitPtr unit, vec2 pos, vec2 normal) override
	{
        HitUnit(unit, pos, normal, m_selfDmg, m_bounceOnCollide);
	}

    bool checkLaserUpgrade() {
        auto laserUpgrade = cast<Skills::LaserUpgrade@>(cast<PlayerBase>(m_owner).m_skills[6]);
        if (laserUpgrade !is null) {
            @m_laserUpgrade = laserUpgrade;
            return true;
        }
        return false;
    }

    void SetDirection(vec2 dir) override
	{
		m_dir = dir;
		float ang = atan(dir.y, dir.x);
        if (checkLaserUpgrade()) {
            if (m_laserUpgrade.upgradeNum == 1) {
                m_unit.SetUnitScene(m_laser_lvl2.GetSceneName(ang), false);
		        SetScriptParams(ang, m_speed);
                return;
            }
            if (m_laserUpgrade.upgradeNum == 2) {
                m_unit.SetUnitScene(m_laser_lvl3.GetSceneName(ang), false);
		        SetScriptParams(ang, m_speed);
                return;
            }
        } else {
            m_unit.SetUnitScene(m_anim.GetSceneName(ang), false);
		    SetScriptParams(ang, m_speed);
        }
	}

    void Initialize(Actor@ owner, vec2 dir, float intensity, bool husk, Actor@ target, uint weapon) override
	{
        @m_owner = owner;
		SetDirection(dir);
		m_husk = husk;
		m_intensity = intensity;
		PropagateWeaponInformation(m_effects, weapon);
		
		if (m_owner !is null)
		{
			if (m_team == 1)
				m_team = owner.Team;
			m_lastCollision = owner.m_unit;
		}

		m_pos = xy(m_unit.GetPosition());
		PlaySound3D(m_soundShoot, m_unit.GetPosition());
		
		vec2 nDir = vec2(-dir.x, -dir.y);
		array<UnitPtr>@ results = g_scene.QueryRect(m_pos, 1, 1, ~0, RaycastType::Aim);
		for (uint i = 0; i < results.length(); i++)
		{
			if (cast<PlayerBase>(results[i].GetScriptBehavior()) !is null)
				continue;
			if (!HitUnit(results[i], m_pos, nDir, 0, false)) {
                break;
            }
				
		}

		SetSeekTarget(target);

		ProjectileBase::Initialize(owner, dir, intensity, husk, target, weapon);
	}
	
	void Update(int dt) override
	{
		float d = m_speed * dt / 33.0;
		m_ttl = int(m_ttl - d);
		if (m_ttl <= 0)
		{
			m_unit.Destroy();
			return;
		}
        
		UpdateSeeking(m_dir, dt);
		
		vec2 from = m_pos;
		m_pos += m_dir * d;
	
		array<RaycastResult>@ results = g_scene.Raycast(from, m_pos, ~0, RaycastType::Shot);
		for (uint i = 0; i < results.length(); i++)
		{
			RaycastResult res = results[i];
            Actor@ actor = cast<Actor>(res.FetchUnit(g_scene).GetScriptBehavior());
            if (actor !is null && !actor.IsTargetable()) {
                return;
            }
			if (!HitUnit(res.FetchUnit(g_scene), res.point, res.normal, m_selfDmg, false))
				return;
		}
	
		m_unit.SetPosition(m_pos.x, m_pos.y, 0, true);

		UpdateSpeed(m_dir, dt);
	}
	
	bool HitUnit(UnitPtr unit, vec2 pos, vec2 normal, float selfDmg, bool bounce, bool collide = true) override
	{
		if (!unit.IsValid())
			return true;
		
		ref@ b = unit.GetScriptBehavior();
		/*
		IProjectile@ p = cast<IProjectile>(b);
		if (p !is null)
			return true;
		*/

		bool shouldRetarget = false;
		bool shoulPassThrough = false;
		
		auto dt = cast<IDamageTaker>(b);
		if (dt !is null)
		{
			if (dt.ShootThrough(m_owner, pos, m_dir))
				return true;
				
			shoulPassThrough = !dt.Impenetrable();
			if (dt is m_owner && selfDmg > 0)
			{
				if (m_lastCollision != unit)
				{
					m_lastCollision = unit;
					ApplyEffects(m_effects, m_owner, unit, pos, m_dir, m_intensity * selfDmg, m_husk);
                    if (m_laserUpgrade !is null || checkLaserUpgrade()) {
                        for (uint j = 0; j < m_laserUpgrade.m_buffs.length(); j++) {
                            cast<Actor>(unit.GetScriptBehavior()).ApplyBuff(ActorBuff(null, m_laserUpgrade.m_buffs[j], 1.0f, false));
                        }
                    }
				}
			}
			else if (!(FilterAction(cast<Actor>(b), m_owner, m_selfDmg, m_teamDmg, 1, 1) > 0))
				return true;
		}

		if (m_lastCollision != unit)
		{
			m_lastCollision = unit;
			ApplyEffects(m_effects, m_owner, unit, pos, m_dir, m_intensity, m_husk);
            if (m_laserUpgrade !is null || checkLaserUpgrade()) {
                for (uint j = 0; j < m_laserUpgrade.m_buffs.length(); j++) {
                    if (unit.IsValid()) {
                        cast<Actor>(unit.GetScriptBehavior()).ApplyBuff(ActorBuff(null, m_laserUpgrade.m_buffs[j], 1.0f, false));
                    }
                }
            }
			shouldRetarget = true;
		}

        m_unit.Destroy();
		return false;
	}

	/*
	void Update(int dt) override
	{
		RayProjectile::Update(dt);
		m_intensity = max(0.05, m_intensity - (m_speed * dt / 33.0f) / 250.0f);
	}
	*/
}