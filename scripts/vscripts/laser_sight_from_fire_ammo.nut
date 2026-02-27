altupgrades <-
{

	function GetPrimarySlot(player)
	{
		local invTable = {};
		GetInvTable(player, invTable);
		if(!("slot0" in invTable))
		{
			return null;
		}
		local weapon = invTable.slot0;
		if(weapon)
		{
			return weapon.GetClassname();
		}
		return null;
	}

	function upgraderemover(player,weaponclass)
	{
		local weapon = null;
		while(weapon = Entities.FindByClassname(weapon, "weapon_*"))
		{
			if(weapon.GetClassname() == weaponclass)
			{
				if(weapon.GetOwnerEntity() == player)
				{
					//checks whether there's no laser sight
					if(NetProps.GetPropInt(weapon, "m_upgradeBitVec") < 4)
					{
						NetProps.SetPropInt(weapon, "m_upgradeBitVec", 0);
						NetProps.SetPropInt(weapon, "m_nUpgradedPrimaryAmmoLoaded", 0);

					}
					//checks whether there's laser sight
					if(NetProps.GetPropInt(weapon, "m_upgradeBitVec") >= 4)
					{
						NetProps.SetPropInt(weapon, "m_upgradeBitVec", 4);
						NetProps.SetPropInt(weapon, "m_nUpgradedPrimaryAmmoLoaded", 0);
					}
				}
			}
		}
	}

	function OnGameEvent_receive_upgrade(event)
	{
		local player = GetPlayerFromUserID(event.userid);
		local upgrade = event.upgrade;
		printl(upgrade);
		if(upgrade == "INCENDIARY_AMMO")
		{
			player.SwitchToItem(GetPrimarySlot(player));
			local weapon = player.GetActiveWeapon();
			local weaponclass = weapon.GetClassname();
			upgraderemover(player,weaponclass);
			player.GiveUpgrade(2);
		}
		if(upgrade == "EXPLOSIVE_AMMO")
		{
			player.SwitchToItem(GetPrimarySlot(player));
			local weapon = player.GetActiveWeapon();
			local weaponclass = weapon.GetClassname();
			upgraderemover(player,weaponclass);
			player.GiveAmmo(360);
		}
	}
}

__CollectEventCallbacks(altupgrades, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);
