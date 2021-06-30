namespace PlayerHandler
{
	void PlayerChargeLaser(uint8 peer, int id, float charge, vec2 target, int unitId)
	{
		auto skill = cast<Skills::ChargeLaser>(GetPlayerSkill(peer, id));
		if (skill is null)
			return;
			
		skill.DoShoot(charge, target, unitId);
	}
}