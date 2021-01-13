namespace Modifiers
{
	class IncenseTriggerEffect : TriggerEffect, IOwnedUnit
	{
		Actor@ m_owner;
		float m_intensityLocal;
		bool m_husk;

		uint m_weaponInfoLocal;

		UnitProducer@ m_prodArea;

		IncenseTriggerEffect(UnitPtr unit, SValue& params)
		{
			super(unit, params);
			@m_prodArea = Resources::GetUnitProducer(GetParamString(unit, params, "unit-area"));
		}

		void Initialize(Actor@ owner, float intensity, bool husk, uint weaponInfo = 0) override
		{
			@m_owner = owner;
			m_intensityLocal = intensity;
			m_husk = husk;

			m_weaponInfoLocal = weaponInfo;
		}

		void UnitSpawned(UnitPtr unit)
		{
			auto ownedUnit = cast<IOwnedUnit>(unit.GetScriptBehavior());
			if (ownedUnit !is null)
				ownedUnit.Initialize(m_owner.m_unit, m_intensityLocal, m_husk, m_weaponInfoLocal);
		}

		Modifier@ Instance() override { return this; }

		void TriggerEffects(PlayerBase@ player, Actor@ enemy, EffectTrigger trigger) override
		{ 
			if (m_trigger != trigger)
				return;
		
			if (!roll_chance(player, m_chance))
				return;

			if (m_timeoutC > 0)
				return;
			
			m_timeoutC = m_timeout;

			if (m_timeoutC > 0 && m_cooldownIcon !is null)
			{
				auto hud = GetHUD();
				if (hud !is null)
					hud.ShowBuffIcon(player, this);
			}

			if (m_counter > 0)
			{
				if (--m_counterC > 0)
					return;

				m_counterC = m_counter;
			}
			
			if (m_ignoreNoLootUnits && enemy !is null)
			{
				auto behavior = cast<CompositeActorBehavior>(enemy);
				if (behavior !is null && behavior.m_noLoot)
					return;
			}

			UnitPtr target;
			if (m_targetSelf)
			{
				target = player.m_unit;

				if (player.GetHealth() > m_requiredHp)
					return;
			}
			else if (enemy !is null)
			{
			
				target = enemy.m_unit;
				if (!enemy.IsTargetable())
					return;

				if (enemy.GetHealth() > m_requiredHp)
					return;
			}
			
			Trigger(player, target);
			UnitSpawned(m_prodArea.Produce(g_scene, player.m_unit.GetPosition()));
		}
	}
}
