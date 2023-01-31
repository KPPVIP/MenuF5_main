ESX = nil

local PersonalMenu = {
	ItemSelected = {},
	ItemIndex = {},
	WeaponData = {},
	WalletIndex = {},
	WalletList = {_U('wallet_option_give'), _U('wallet_option_drop')},
	BillData = {},
	ClothesButtons = {'torso', 'pants', 'shoes', 'bag', 'bproof'},
	AccessoriesButtons = {'Ears', 'Glasses', 'Helmet', 'Mask'},
	DoorState = {
		FrontLeft = false,
		FrontRight = false,
		BackLeft = false,
		BackRight = false,
		Hood = false,
		Trunk = false
	},
	DoorIndex = 1,
	DoorList = {_U('vehicle_door_frontleft'), _U('vehicle_door_frontright'), _U('vehicle_door_backleft'), _U('vehicle_door_backright')},
}

Player = {
	isDead = false,
	inAnim = false,
	crouched = false,
	handsup = false,
	pointing = false,
	noclip = false,
	godmode = false,
	ghostmode = false,
	showCoords = false,
	showName = false,
	gamerTags = {},
	group = 'user'
}

local societymoney, societymoney2 = nil, nil

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(10)
	end

	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(10)
	end

	if Config.DoubleJob then
		while ESX.GetPlayerData().job2 == nil do
			Citizen.Wait(10)
		end
	end

	ESX.PlayerData = ESX.GetPlayerData()

	while actualSkin == nil do
		TriggerEvent('skinchanger:getSkin', function(skin)
			actualSkin = skin
		end)

		Citizen.Wait(10)
	end

	RefreshMoney()

	if Config.DoubleJob then
		RefreshMoney2()
	end

	PersonalMenu.WeaponData = ESX.GetWeaponList()

	for i = 1, #PersonalMenu.WeaponData, 1 do
		if PersonalMenu.WeaponData[i].name == 'WEAPON_UNARMED' then
			PersonalMenu.WeaponData[i] = nil
		else
			PersonalMenu.WeaponData[i].hash = GetHashKey(PersonalMenu.WeaponData[i].name)
		end
	end

	RMenu.Add('rageui', 'personal', RageUI.CreateMenu(Config.MenuTitle, ("~b~Menu Intéraction"),  0, 0, 'commonmenu', 'interaction_bgd', 0, 0, 0, 255))

	RMenu.Add('personal', 'inventory', RageUI.CreateSubMenu(RMenu.Get('rageui', 'personal'), ('Inventaire~b~')))
	RMenu.Add('personal', 'loadout', RageUI.CreateSubMenu(RMenu.Get('rageui', 'personal'), ('Armes~b~')))
	RMenu.Add('personal', 'wallet', RageUI.CreateSubMenu(RMenu.Get('rageui', 'personal'), ('Portefeuille~b~')))
	RMenu.Add('personal', 'billing', RageUI.CreateSubMenu(RMenu.Get('rageui', 'personal'), ('Facture~b~')))
	RMenu.Add('personal', 'divers', RageUI.CreateSubMenu(RMenu.Get('rageui', 'personal'), ('Menu Divers')))
	RMenu.Add('personal', 'touche', RageUI.CreateSubMenu(RMenu.Get('rageui', 'personal'), ('Touches du Serveur')))
	RMenu.Add('personal', 'vehicle', RageUI.CreateSubMenu(RMenu.Get('rageui', 'personal'), ('Gestion Vehicule')), function()
		if IsPedSittingInAnyVehicle(plyPed) then
			if (GetPedInVehicleSeat(GetVehiclePedIsIn(plyPed, false), -1) == plyPed) then
				return true
			end
		end

		return false
	end)

	RMenu.Add('personal', 'boss', RageUI.CreateSubMenu(RMenu.Get('rageui', 'personal'), ('Gestion Entreprise')), function()
		if ESX.PlayerData.job ~= nil and ESX.PlayerData.job.grade_name == 'boss' then
			return true
		end

		return false
	end)

	if Config.DoubleJob then
		RMenu.Add('personal', 'boss2', RageUI.CreateSubMenu(RMenu.Get('rageui', 'personal'), ('Gestion Organistation')), function()
			if Config.DoubleJob then
				if ESX.PlayerData.job2 ~= nil and ESX.PlayerData.job2.grade_name == 'boss' then
					return true
				end
			end

			return false
		end)
	end

	RMenu.Add('personal', 'admin', RageUI.CreateSubMenu(RMenu.Get('rageui', 'personal'), ('Menu Administratif')), function()
		if Player.group ~= nil and (Player.group == 'mod' or Player.group == 'admin' or Player.group == 'superadmin' or Player.group == 'owner' or Player.group == '_dev') then
			return true
		end

		return false
	end)

	RMenu.Add('inventory', 'actions', RageUI.CreateSubMenu(RMenu.Get('personal', 'inventory'), _U('inventory_actions_title')))
	RMenu.Get('inventory', 'actions').Closed = function()
		PersonalMenu.ItemSelected = nil
	end

	RMenu.Add('loadout', 'actions', RageUI.CreateSubMenu(RMenu.Get('personal', 'loadout'), _U('loadout_actions_title')))
	RMenu.Get('loadout', 'actions').Closed = function()
		PersonalMenu.ItemSelected = nil
    end
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
	ESX.PlayerData = xPlayer
end)

AddEventHandler('esx:onPlayerDeath', function()
	Player.isDead = true
	RageUI.CloseAll()
	ESX.UI.Menu.CloseAll()
end)

AddEventHandler('playerSpawned', function()
	Player.isDead = false
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	ESX.PlayerData.job = job
	RefreshMoney()
end)

RegisterNetEvent('esx:setJob2')
AddEventHandler('esx:setJob2', function(job2)
	ESX.PlayerData.job2 = job2
	RefreshMoney2()
end)

RegisterNetEvent('esx_addonaccount:setMoney')
AddEventHandler('esx_addonaccount:setMoney', function(society, money)
	if ESX.PlayerData.job ~= nil and ESX.PlayerData.job.grade_name == 'boss' and 'society_' .. ESX.PlayerData.job.name == society then
		UpdateSocietyMoney(money)
	end
	if ESX.PlayerData.job2 ~= nil and ESX.PlayerData.job2.grade_name == 'boss' and 'society_' .. ESX.PlayerData.job2.name == society then
		UpdateSociety2Money(money)
	end
end)

-- Weapon Menu --
RegisterNetEvent('KorioZ-PersonalMenu:Weapon_addAmmoToPedC')
AddEventHandler('KorioZ-PersonalMenu:Weapon_addAmmoToPedC', function(value, quantity)
	local weaponHash = GetHashKey(value)

	if HasPedGotWeapon(plyPed, weaponHash, false) and value ~= 'WEAPON_UNARMED' then
		AddAmmoToPed(plyPed, value, quantity)
	end
end)

-- Admin Menu --
RegisterNetEvent('KorioZ-PersonalMenu:Admin_BringC')
AddEventHandler('KorioZ-PersonalMenu:Admin_BringC', function(plyCoords)
	SetEntityCoords(plyPed, plyCoords)
end)

function RefreshMoney()
	if ESX.PlayerData.job ~= nil and ESX.PlayerData.job.grade_name == 'boss' then
		ESX.TriggerServerCallback('esx_society:getSocietyMoney', function(money)
			UpdateSocietyMoney(money)
		end, ESX.PlayerData.job.name)
	end
end

function RefreshMoney2()
	if ESX.PlayerData.job2 ~= nil and ESX.PlayerData.job2.grade_name == 'boss' then
		ESX.TriggerServerCallback('esx_society:getSocietyMoney', function(money)
			UpdateSociety2Money(money)
		end, ESX.PlayerData.job2.name)
	end
end

function UpdateSocietyMoney(money)
	societymoney = ESX.Math.GroupDigits(money)
end

function UpdateSociety2Money(money)
	societymoney2 = ESX.Math.GroupDigits(money)
end

--Message text joueur
function Text(text)
	SetTextColour(186, 186, 186, 255)
	SetTextFont(0)
	SetTextScale(0.378, 0.378)
	SetTextWrap(0.0, 1.0)
	SetTextCentre(false)
	SetTextDropshadow(0, 0, 0, 0, 255)
	SetTextEdge(1, 0, 0, 0, 205)
	BeginTextCommandDisplayText('STRING')
	AddTextComponentSubstringPlayerName(text)
	EndTextCommandDisplayText(0.017, 0.977)
end

function KeyboardInput(entryTitle, textEntry, inputText, maxLength)
	AddTextEntry(entryTitle, textEntry)
	DisplayOnscreenKeyboard(1, entryTitle, '', inputText, '', '', '', maxLength)
	blockinput = true

	while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do
		Citizen.Wait(0)
	end

	if UpdateOnscreenKeyboard() ~= 2 then
		local result = GetOnscreenKeyboardResult()
		Citizen.Wait(500)
		blockinput = false
		return result
	else
		Citizen.Wait(500)
		blockinput = false
		return nil
	end
end

function getCamDirection()
	local heading = GetGameplayCamRelativeHeading() + GetEntityHeading(plyPed)
	local pitch = GetGameplayCamRelativePitch()
	local coords = vector3(-math.sin(heading * math.pi / 180.0), math.cos(heading * math.pi / 180.0), math.sin(pitch * math.pi / 180.0))
	local len = math.sqrt((coords.x * coords.x) + (coords.y * coords.y) + (coords.z * coords.z))

	if len ~= 0 then
		coords = coords / len
	end

	return coords
end

function startAttitude(lib, anim)
	ESX.Streaming.RequestAnimSet(anim, function()
		SetPedMotionBlur(plyPed, false)
		SetPedMovementClipset(plyPed, anim, true)
		RemoveAnimSet(anim)
	end)
end

function startAnim(lib, anim)
	ESX.Streaming.RequestAnimDict(lib, function()
		TaskPlayAnim(plyPed, lib, anim, 8.0, -8.0, -1, 0, 0, false, false, false)
		RemoveAnimDict(lib)
	end)
end

function startAnimAction(lib, anim)
	ESX.Streaming.RequestAnimDict(lib, function()
		TaskPlayAnim(plyPed, lib, anim, 8.0, 1.0, -1, 49, 0, false, false, false)
		RemoveAnimDict(lib)
	end)
end

function setUniform(value, plyPed)
	ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
		TriggerEvent('skinchanger:getSkin', function(skina)
			if value == 'torso' then
				startAnimAction('clothingtie', 'try_tie_neutral_a')
				Citizen.Wait(1000)
				Player.handsup, Player.pointing = false, false
				ClearPedTasks(plyPed)

				if skin.torso_1 ~= skina.torso_1 then
					TriggerEvent('skinchanger:loadClothes', skina, {['torso_1'] = skin.torso_1, ['torso_2'] = skin.torso_2, ['tshirt_1'] = skin.tshirt_1, ['tshirt_2'] = skin.tshirt_2, ['arms'] = skin.arms})
				else
					TriggerEvent('skinchanger:loadClothes', skina, {['torso_1'] = 15, ['torso_2'] = 0, ['tshirt_1'] = 15, ['tshirt_2'] = 0, ['arms'] = 15})
				end
			elseif value == 'pants' then
				if skin.pants_1 ~= skina.pants_1 then
					TriggerEvent('skinchanger:loadClothes', skina, {['pants_1'] = skin.pants_1, ['pants_2'] = skin.pants_2})
				else
					if skin.sex == 0 then
						TriggerEvent('skinchanger:loadClothes', skina, {['pants_1'] = 61, ['pants_2'] = 1})
					else
						TriggerEvent('skinchanger:loadClothes', skina, {['pants_1'] = 15, ['pants_2'] = 0})
					end
				end
			elseif value == 'shoes' then
				if skin.shoes_1 ~= skina.shoes_1 then
					TriggerEvent('skinchanger:loadClothes', skina, {['shoes_1'] = skin.shoes_1, ['shoes_2'] = skin.shoes_2})
				else
					if skin.sex == 0 then
						TriggerEvent('skinchanger:loadClothes', skina, {['shoes_1'] = 34, ['shoes_2'] = 0})
					else
						TriggerEvent('skinchanger:loadClothes', skina, {['shoes_1'] = 35, ['shoes_2'] = 0})
					end
				end
			elseif value == 'bag' then
				if skin.bags_1 ~= skina.bags_1 then
					TriggerEvent('skinchanger:loadClothes', skina, {['bags_1'] = skin.bags_1, ['bags_2'] = skin.bags_2})
				else
					TriggerEvent('skinchanger:loadClothes', skina, {['bags_1'] = 0, ['bags_2'] = 0})
				end
			elseif value == 'bproof' then
				startAnimAction('clothingtie', 'try_tie_neutral_a')
				Citizen.Wait(1000)
				Player.handsup, Player.pointing = false, false
				ClearPedTasks(plyPed)

				if skin.bproof_1 ~= skina.bproof_1 then
					TriggerEvent('skinchanger:loadClothes', skina, {['bproof_1'] = skin.bproof_1, ['bproof_2'] = skin.bproof_2})
				else
					TriggerEvent('skinchanger:loadClothes', skina, {['bproof_1'] = 0, ['bproof_2'] = 0})
				end
			end
		end)
	end)
end

function setAccessory(accessory)
	ESX.TriggerServerCallback('esx_accessories:get', function(hasAccessory, accessorySkin)
		local _accessory = (accessory):lower()

		if hasAccessory then
			TriggerEvent('skinchanger:getSkin', function(skin)
				local mAccessory = -1
				local mColor = 0

				if _accessory == 'ears' then
					startAnimAction('mini@ears_defenders', 'takeoff_earsdefenders_idle')
					Citizen.Wait(250)
					Player.handsup, Player.pointing = false, false
					ClearPedTasks(plyPed)
				elseif _accessory == 'glasses' then
					mAccessory = 0
					startAnimAction('clothingspecs', 'try_glasses_positive_a')
					Citizen.Wait(1000)
					Player.handsup, Player.pointing = false, false
					ClearPedTasks(plyPed)
				elseif _accessory == 'helmet' then
					startAnimAction('missfbi4', 'takeoff_mask')
					Citizen.Wait(1000)
					Player.handsup, Player.pointing = false, false
					ClearPedTasks(plyPed)
				elseif _accessory == 'mask' then
					mAccessory = 0
					startAnimAction('missfbi4', 'takeoff_mask')
					Citizen.Wait(850)
					Player.handsup, Player.pointing = false, false
					ClearPedTasks(plyPed)
				end

				if skin[_accessory .. '_1'] == mAccessory then
					mAccessory = accessorySkin[_accessory .. '_1']
					mColor = accessorySkin[_accessory .. '_2']
				end

				local accessorySkin = {}
				accessorySkin[_accessory .. '_1'] = mAccessory
				accessorySkin[_accessory .. '_2'] = mColor
				TriggerEvent('skinchanger:loadClothes', skin, accessorySkin)
			end)
		else
			if _accessory == 'ears' then
				ESX.ShowNotification(_U('accessories_no_ears'))
			elseif _accessory == 'glasses' then
				ESX.ShowNotification(_U('accessories_no_glasses'))
			elseif _accessory == 'helmet' then
				ESX.ShowNotification(_U('accessories_no_helmet'))
			elseif _accessory == 'mask' then
				ESX.ShowNotification(_U('accessories_no_mask'))
			end
		end
	end, accessory)
end

function CheckQuantity(number)
	number = tonumber(number)

	if type(number) == 'number' then
		number = ESX.Math.Round(number)

		if number > 0 then
			return true, number
		end
	end

	return false, number
end

function RenderPersonalMenu()
	RageUI.DrawContent({header = true, instructionalButton = true}, function()
		for i = 1, #RMenu['personal'], 1 do
			if type(RMenu['personal'][i].Restriction) == 'function' then
				if RMenu['personal'][i].Restriction() then
					RageUI.Button(RMenu['personal'][i].Menu.Title, nil, {RightLabel = ">"}, true, function() end, RMenu['personal'][i].Menu)
				else
					RageUI.Button(RMenu['personal'][i].Menu.Title, nil, {RightBadge = RageUI.BadgeStyle.Lock}, false, function() end, RMenu['personal'][i].Menu)
				end
			else
				RageUI.Button(RMenu['personal'][i].Menu.Title, nil, {RightLabel = ">"}, true, function() end, RMenu['personal'][i].Menu)
			end
		end
	end)
end

function RenderActionsMenu(type)
	RageUI.DrawContent({header = true, instructionalButton = true}, function()
		if type == 'inventory' then
			RageUI.Button(_U('inventory_use_button'), "", {}, true, function(Hovered, Active, Selected)
				if (Selected) then
					if PersonalMenu.ItemSelected.usable then
						TriggerServerEvent('esx:useItem', PersonalMenu.ItemSelected.name)
					else
						ESX.ShowNotification(_U('not_usable', PersonalMenu.ItemSelected.label))
					end
				end
			end)

			RageUI.Button(_U('inventory_give_button'), "", {}, true, function(Hovered, Active, Selected)
				if (Selected) then
					local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()

					if closestDistance ~= -1 and closestDistance <= 3 then
						local closestPed = GetPlayerPed(closestPlayer)

						if not IsPedSittingInAnyVehicle(closestPed) then
							if PersonalMenu.ItemIndex[PersonalMenu.ItemSelected.name] ~= nil and PersonalMenu.ItemSelected.count > 0 then
								TriggerServerEvent('esx:giveItem', GetPlayerServerId(closestPlayer), 'item_standard', PersonalMenu.ItemSelected.name, PersonalMenu.ItemIndex[PersonalMenu.ItemSelected.name])
								RageUI.CloseAll()
							else
								ESX.ShowNotification(_U('amount_invalid'))
							end
						else
							ESX.ShowNotification(_U('in_vehicle_give', PersonalMenu.ItemSelected.label))
						end
					else
						ESX.ShowNotification(_U('players_nearby'))
					end
				end
			end)

			RageUI.Button(_U('inventory_drop_button'), "", {RightBadge = RageUI.BadgeStyle.Alert}, true, function(Hovered, Active, Selected)
				if (Selected) then
					if PersonalMenu.ItemSelected.canRemove then
						if not IsPedSittingInAnyVehicle(plyPed) then
							if PersonalMenu.ItemIndex[PersonalMenu.ItemSelected.name] ~= nil then
								TriggerServerEvent('esx:retirerItem', 'item_standard', PersonalMenu.ItemSelected.name, PersonalMenu.ItemIndex[PersonalMenu.ItemSelected.name])
								RageUI.CloseAll()
							else
								ESX.ShowNotification(_U('amount_invalid'))
							end
						else
							ESX.ShowNotification(_U('in_vehicle_drop', PersonalMenu.ItemSelected.label))
						end
					else
						ESX.ShowNotification(_U('not_droppable', PersonalMenu.ItemSelected.label))
					end
				end
			end)
		elseif type == 'loadout' then
			if HasPedGotWeapon(plyPed, PersonalMenu.ItemSelected.hash, false) then
				RageUI.Button(_U('loadout_give_button'), "", {}, true, function(Hovered, Active, Selected)
					if (Selected) then
						local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()

						if closestDistance ~= -1 and closestDistance <= 3 then
							local closestPed = GetPlayerPed(closestPlayer)

							if not IsPedSittingInAnyVehicle(closestPed) then
								local ammo = GetAmmoInPedWeapon(plyPed, PersonalMenu.ItemSelected.hash)
								TriggerServerEvent('esx:giveItem', GetPlayerServerId(closestPlayer), 'item_weapon', PersonalMenu.ItemSelected.name, ammo)
								RageUI.CloseAll()
							else
								ESX.ShowNotification(_U('in_vehicle_give', PersonalMenu.ItemSelected.label))
							end
						else
							ESX.ShowNotification(_U('players_nearby'))
						end
					end
				end)

				RageUI.Button(_U('loadout_givemun_button'), "", {RightBadge = RageUI.BadgeStyle.Ammo}, true, function(Hovered, Active, Selected)
					if (Selected) then
						local post, quantity = CheckQuantity(KeyboardInput('KORIOZ_BOX_AMMO_AMOUNT', _U('dialogbox_amount_ammo'), '', 8))

						if post then
							local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()

							if closestDistance ~= -1 and closestDistance <= 3 then
								local closestPed = GetPlayerPed(closestPlayer)

								if not IsPedSittingInAnyVehicle(closestPed) then
									local ammo = GetAmmoInPedWeapon(plyPed, PersonalMenu.ItemSelected.hash)

									if ammo > 0 then
										if quantity <= ammo and quantity >= 0 then
											local finalAmmo = math.floor(ammo - quantity)
											SetPedAmmo(plyPed, PersonalMenu.ItemSelected.name, finalAmmo)

											TriggerServerEvent('KorioZ-PersonalMenu:Weapon_addAmmoToPedS', GetPlayerServerId(closestPlayer), PersonalMenu.ItemSelected.name, quantity)
											ESX.ShowNotification(_U('gave_ammo', quantity, GetPlayerName(closestPlayer)))
											RageUI.CloseAll()
										else
											ESX.ShowNotification(_U('not_enough_ammo'))
										end
									else
										ESX.ShowNotification(_U('no_ammo'))
									end
								else
									ESX.ShowNotification(_U('in_vehicle_give', PersonalMenu.ItemSelected.label))
								end
							else
								ESX.ShowNotification(_U('players_nearby'))
							end
						else
							ESX.ShowNotification(_U('amount_invalid'))
						end
					end
				end)

				RageUI.Button(_U('loadout_drop_button'), "", {RightBadge = RageUI.BadgeStyle.Alert}, true, function(Hovered, Active, Selected)
					if (Selected) then
						if not IsPedSittingInAnyVehicle(plyPed) then
							TriggerServerEvent('esx:retirerItem', 'item_weapon', PersonalMenu.ItemSelected.name)
							RageUI.CloseAll()
						else
							ESX.ShowNotification(_U('in_vehicle_drop', PersonalMenu.ItemSelected.label))
						end
					end
				end)
			else
				RageUI.GoBack()
			end
		end
	end)
end

function RenderInventoryMenu()
	RageUI.DrawContent({header = true, instructionalButton = true}, function()
		for i = 1, #ESX.PlayerData.inventory, 1 do
			if ESX.PlayerData.inventory[i].count > 0 then
				local invCount = {}

				for i = 1, ESX.PlayerData.inventory[i].count, 1 do
					table.insert(invCount, i)
				end

				RageUI.List(ESX.PlayerData.inventory[i].label .. ' (' .. ESX.PlayerData.inventory[i].count .. ')', invCount, PersonalMenu.ItemIndex[ESX.PlayerData.inventory[i].name] or 1, nil, {}, true, function(Hovered, Active, Selected, Index)
					if (Selected) then
						PersonalMenu.ItemSelected = ESX.PlayerData.inventory[i]
					end

					PersonalMenu.ItemIndex[ESX.PlayerData.inventory[i].name] = Index
				end, RMenu.Get('inventory', 'actions'))
			end
		end
	end)
end

function RenderWeaponMenu()
	RageUI.DrawContent({header = true, instructionalButton = true}, function()
		for i = 1, #PersonalMenu.WeaponData, 1 do
			if HasPedGotWeapon(plyPed, PersonalMenu.WeaponData[i].hash, false) then
				local ammo = GetAmmoInPedWeapon(plyPed, PersonalMenu.WeaponData[i].hash)

				RageUI.Button(PersonalMenu.WeaponData[i].label .. ' [' .. ammo .. ']', nil, {RightLabel = ">"}, true, function(Hovered, Active, Selected)
					if (Selected) then
						PersonalMenu.ItemSelected = PersonalMenu.WeaponData[i]
					end
				end, RMenu.Get('loadout', 'actions'))
			end
		end
	end)
end

function RenderWalletMenu()
	RageUI.DrawContent({header = true, instructionalButton = true}, function()
		RageUI.Button(_U('wallet_job_button', ESX.PlayerData.job.label, ESX.PlayerData.job.grade_label), nil, {}, true, function() end)

		if Config.DoubleJob then
			RageUI.Button(_U('wallet_job2_button', ESX.PlayerData.job2.label, ESX.PlayerData.job2.grade_label), nil, {}, true, function() end)
		end

		if PersonalMenu.WalletIndex['money'] == nil then PersonalMenu.WalletIndex['money'] = 1 end
		RageUI.List(_U('wallet_money_button', ESX.Math.GroupDigits(ESX.PlayerData.money)), PersonalMenu.WalletList, PersonalMenu.WalletIndex['money'] or 1, nil, {}, true, function(Hovered, Active, Selected, Index)
			if (Selected) then
				if Index == 1 then
					local post, quantity = CheckQuantity(KeyboardInput('KORIOZ_BOX_AMOUNT', _U('dialogbox_amount'), '', 8))

					if post then
						local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()

						if closestDistance ~= -1 and closestDistance <= 3 then
							local closestPed = GetPlayerPed(closestPlayer)

							if not IsPedSittingInAnyVehicle(closestPed) then
								TriggerServerEvent('esx:giveItem', GetPlayerServerId(closestPlayer), 'item_money', 'money', quantity)
								RageUI.CloseAll()
							else
								ESX.ShowNotification(_U('in_vehicle_give', 'de l\'argent'))
							end
						else
							ESX.ShowNotification(_U('players_nearby'))
						end
					else
						ESX.ShowNotification(_U('amount_invalid'))
					end
				elseif Index == 2 then
					local post, quantity = CheckQuantity(KeyboardInput('KORIOZ_BOX_AMOUNT', _U('dialogbox_amount'), '', 8))

					if post then
						if not IsPedSittingInAnyVehicle(plyPed) then
							TriggerServerEvent('esx:retirerItem', 'item_money', 'money', quantity)
							RageUI.CloseAll()
						else
							ESX.ShowNotification(_U('in_vehicle_drop', 'de l\'argent'))
						end
					else
						ESX.ShowNotification(_U('amount_invalid'))
					end
				end
			end

			PersonalMenu.WalletIndex['money'] = Index
		end)

		for i = 1, #ESX.PlayerData.accounts, 1 do
			if ESX.PlayerData.accounts[i].name == 'bank' then
				RageUI.Button(_U('wallet_bankmoney_button', ESX.Math.GroupDigits(ESX.PlayerData.accounts[i].money)), nil, {}, true, function() end)
			end

			if ESX.PlayerData.accounts[i].name == 'black_money' then
				if PersonalMenu.WalletIndex[ESX.PlayerData.accounts[i].name] == nil then PersonalMenu.WalletIndex[ESX.PlayerData.accounts[i].name] = 1 end
				RageUI.List(_U('wallet_blackmoney_button', ESX.Math.GroupDigits(ESX.PlayerData.accounts[i].money)), PersonalMenu.WalletList, PersonalMenu.WalletIndex[ESX.PlayerData.accounts[i].name] or 1, nil, {}, true, function(Hovered, Active, Selected, Index)
					if (Selected) then
						if Index == 1 then
							local post, quantity = CheckQuantity(KeyboardInput('KORIOZ_BOX_AMOUNT', _U('dialogbox_amount'), '', 8))

							if post then
								local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()

								if closestDistance ~= -1 and closestDistance <= 3 then
									local closestPed = GetPlayerPed(closestPlayer)

									if not IsPedSittingInAnyVehicle(closestPed) then
										TriggerServerEvent('esx:giveItem', GetPlayerServerId(closestPlayer), 'item_account', ESX.PlayerData.accounts[i].name, quantity)
										RageUI.CloseAll()
									else
										ESX.ShowNotification(_U('in_vehicle_give', 'de l\'argent'))
									end
								else
									ESX.ShowNotification(_U('players_nearby'))
								end
							else
								ESX.ShowNotification(_U('amount_invalid'))
							end
						elseif Index == 2 then
							local post, quantity = CheckQuantity(KeyboardInput('KORIOZ_BOX_AMOUNT', _U('dialogbox_amount'), '', 8))

							if post then
								if not IsPedSittingInAnyVehicle(plyPed) then
									TriggerServerEvent('esx:retirerItem', 'item_account', ESX.PlayerData.accounts[i].name, quantity)
									RageUI.CloseAll()
								else
									ESX.ShowNotification(_U('in_vehicle_drop', 'de l\'argent'))
								end
							else
								ESX.ShowNotification(_U('amount_invalid'))
							end
						end
					end

					PersonalMenu.WalletIndex[ESX.PlayerData.accounts[i].name] = Index
				end)
			end
		end

		if Config.JSFourIDCard then
			RageUI.Button(_U('wallet_show_idcard_button'), nil, {}, true, function(Hovered, Active, Selected)
				if (Selected) then
					local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()

					if closestDistance ~= -1 and closestDistance <= 3.0 then
						TriggerServerEvent('jsfour-idcard:open', GetPlayerServerId(PlayerId()), GetPlayerServerId(closestPlayer))
					else
						ESX.ShowNotification(_U('players_nearby'))
					end
				end
			end)

			RageUI.Button(_U('wallet_check_idcard_button'), nil, {}, true, function(Hovered, Active, Selected)
				if (Selected) then
					TriggerServerEvent('jsfour-idcard:open', GetPlayerServerId(PlayerId()), GetPlayerServerId(PlayerId()))
				end
			end)

			RageUI.Button(_U('wallet_show_driver_button'), nil, {}, true, function(Hovered, Active, Selected)
				if (Selected) then
					local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()

					if closestDistance ~= -1 and closestDistance <= 3.0 then
						TriggerServerEvent('jsfour-idcard:open', GetPlayerServerId(PlayerId()), GetPlayerServerId(closestPlayer), 'driver')
					else
						ESX.ShowNotification(_U('players_nearby'))
					end
				end
			end)

			RageUI.Button(_U('wallet_check_driver_button'), nil, {}, true, function(Hovered, Active, Selected)
				if (Selected) then
					TriggerServerEvent('jsfour-idcard:open', GetPlayerServerId(PlayerId()), GetPlayerServerId(PlayerId()), 'driver')
				end
			end)

			RageUI.Button(_U('wallet_show_firearms_button'), nil, {}, true, function(Hovered, Active, Selected)
				if (Selected) then
					local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()

					if closestDistance ~= -1 and closestDistance <= 3.0 then
						TriggerServerEvent('jsfour-idcard:open', GetPlayerServerId(PlayerId()), GetPlayerServerId(closestPlayer), 'weapon')
					else
						ESX.ShowNotification(_U('players_nearby'))
					end
				end
			end)

			RageUI.Button(_U('wallet_check_firearms_button'), nil, {}, true, function(Hovered, Active, Selected)
				if (Selected) then
					TriggerServerEvent('jsfour-idcard:open', GetPlayerServerId(PlayerId()), GetPlayerServerId(PlayerId()), 'weapon')
				end
			end)
		end
	end)
end

function RenderBillingMenu()
	RageUI.DrawContent({header = true, instructionalButton = true}, function()
		for i = 1, #PersonalMenu.BillData, 1 do
			RageUI.Button(PersonalMenu.BillData[i].label, nil, {RightLabel = '$' .. ESX.Math.GroupDigits(PersonalMenu.BillData[i].amount)}, true, function(Hovered, Active, Selected)
				if (Selected) then
					ESX.TriggerServerCallback('esx_billing:payBill', function()
						ESX.TriggerServerCallback('KorioZ-PersonalMenu:Bill_getBills', function(bills)
							PersonalMenu.BillData = bills
						end)
					end, PersonalMenu.BillData[i].id)
				end
			end)
		end
	end)
end

function RenderClothesMenu()
	RageUI.DrawContent({header = true, instructionalButton = true}, function()
		for i = 1, #PersonalMenu.ClothesButtons, 1 do
			RageUI.Button(_U(('clothes_%s'):format(PersonalMenu.ClothesButtons[i])), nil, {RightBadge = RageUI.BadgeStyle.Clothes}, true, function(Hovered, Active, Selected)
				if (Selected) then
					setUniform(PersonalMenu.ClothesButtons[i], plyPed)
				end
			end)
		end
	end)
end

function RenderAccessoriesMenu()
	RageUI.DrawContent({header = true, instructionalButton = true}, function()
		for i = 1, #PersonalMenu.AccessoriesButtons, 1 do
			RageUI.Button(_U(('accessories_%s'):format((PersonalMenu.AccessoriesButtons[i]:lower()))), nil, {RightBadge = RageUI.BadgeStyle.Clothes}, true, function(Hovered, Active, Selected)
				if (Selected) then
					setAccessory(PersonalMenu.AccessoriesButtons[i])
				end
			end)
		end
	end)
end


-- Dormir/Se Réveiller
local ragdoll = false
  function setRagdoll(flag)
	ragdoll = flag
  end
  Citizen.CreateThread(function()
	while true do
	  Citizen.Wait(0)
	  if ragdoll then
		SetPedToRagdoll(GetPlayerPed(-1), 1000, 1000, 0, 0, 0, 0)
	  end
	end
  end)
  
  ragdol = true
  RegisterNetEvent("Ragdoll")
  AddEventHandler("Ragdoll", function()
	  if ( ragdol ) then
		  setRagdoll(true)
		  ragdol = false
	  else
		  setRagdoll(false)
		  ragdol = true
	  end
  end)

function Ragdoll()
	TriggerEvent("Ragdoll", source)
end

-- GPS/GPS OFF
RegisterNetEvent('no_hud:GPSACTIVE')
AddEventHandler('no_hud:GPSACTIVE', function()
	DisplayRadar(true)
end)

RegisterNetEvent('no_hud:GPSDESACTIVE')
AddEventHandler('no_hud:GPSDESACTIVE', function()
	DisplayRadar(false)
end)


local audioTroisD = false
function RendertoucheMenu()
	RageUI.DrawContent({header = true, instructionalButton = true}, function()

		RageUI.Button("Télephone ", nil, {RightLabel = "F1"},true, function(Hovered, Active, Selected)
		if (Selected) then   

		end
		end) 

		RageUI.Button("Menu Emotes ", nil, {RightLabel = "F2"},true, function(Hovered, Active, Selected)
		if (Selected) then   
	
		end
		end)

		RageUI.Button("Menu Personnel ", nil, {RightLabel = "F5"},true, function(Hovered, Active, Selected)
		if (Selected) then   
		
		end
		end)

		RageUI.Button("Menu Métiers ", nil, {RightLabel = "F6"},true, function(Hovered, Active, Selected)
		if (Selected) then   
			
		end
		end)

		RageUI.Button("Menu Radio ", nil, {RightLabel = "F9"},true, function(Hovered, Active, Selected)
		if (Selected) then   
				
		end
		end)
		
		RageUI.Button(" Menu Vetement ", nil, {RightLabel = "Y"},true, function(Hovered, Active, Selected)
			if (Selected) then   
	
		end
		end) 

		RageUI.Button("Verouiller/ Déverouiller son Vehicule ", nil, {RightLabel = "U"},true, function(Hovered, Active, Selected)
			if (Selected) then   
	
		end
		end) 

		RageUI.Button("Mode de Voix ", nil, {RightLabel = "H"},true, function(Hovered, Active, Selected)
			if (Selected) then   
		
		end
		end)

		RageUI.Button("Menu Carte Sim ", nil, {RightLabel = "K"},true, function(Hovered, Active, Selected)
			if (Selected) then   
		
		end
		end)

		RageUI.Button("Coffre de Vehicule ", nil, {RightLabel = "L"},true, function(Hovered, Active, Selected)
			if (Selected) then   
		
		end
		end)
		
		RageUI.Button("Annuler Annimation ", nil, {RightLabel = "X"},true, function(Hovered, Active, Selected)
			if (Selected) then   
		
		end
		end)

		RageUI.Button("Lever les Mains ", nil, {RightLabel = "²"},true, function(Hovered, Active, Selected)
			if (Selected) then   
		
		end
		end)

		RageUI.Button("Montrer du Doigt ", nil, {RightLabel = "X"},true, function(Hovered, Active, Selected)
			if (Selected) then   
		
		end
		end)

		RageUI.Button("Dormir / Se Révbeiller ", nil, {RightLabel = ","},true, function(Hovered, Active, Selected)
			if (Selected) then   
		
		end
		end)
	end)
end


function RenderDiversMenuMenu()
	RageUI.DrawContent({header = true, instructionalButton = true}, function()


		RageUI.Button("Appuye ici pour voir ton ID", nil, {}, true, function(Hovered, Active, Selected)
            if (Selected) then
				RageUI.Popup({message = '~r~StreetyLifeV2 ~w~information , ton ID est le : ~r~'.. GetPlayerServerId(PlayerId()) ..''})
            end
		end)

		RageUI.Button("Appuye ici pour rejoindre le discord", nil, {}, true, function(Hovered, Active, Selected)
            if (Selected) then
				RageUI.Popup({message = '~r~StreetyLifeV2 ~w~information , le lien discord est : ~r~ discord.gg/yw5V4jC9Xe'})
            end
		end)

		RageUI.Button("Mode Cinématique", nil, {}, true, function(Hovered, Active, Selected)
            if (Selected) then
				RageUI.CloseAll()
				ExecuteCommand('cinematique')
			end
		end)

		RageUI.Button("Vision Normal", "Changer la Vue en Normal !", {}, true, function(Hovered, Active, Selected)
            if (Selected) then
                SetTimecycleModifier('')
            end
		end)
		
        RageUI.Button("Vue & lumières améliorées", "Changer la Vue en Amélioré !", {}, true, function(Hovered, Active, Selected)
            if (Selected) then
                SetTimecycleModifier('tunnel')
            end
		end)
		
        RageUI.Button("Couleurs amplifiées", "Changer la Vue en Couleurs Amplifiées !", {}, true, function(Hovered, Active, Selected)
            if (Selected) then
                SetTimecycleModifier('rply_saturation')
            end
		end)
		
        RageUI.Button("Noir & blancs", "Changer la Vue en Noir et Blancs !", {}, true, function(Hovered, Active, Selected)
            if (Selected) then
                SetTimecycleModifier('rply_saturation_neg')
            end
		end)
		
		RageUI.Button("Optimisation", "Optimisation de vos FPS.", { RightBadge = RageUI.BadgeStyle.Tick, Color = {BackgroundColor = { 230, 120, 76, 25 }} }, true, function(Hovered, Active, Selected)
            if (Selected) then
                        DoScreenFadeIn(2000) -- Ecran Noir
                        LoadingPrompt("Optimisation en cours...", 3)
                        DoScreenFadeOut(2000)  -- Ecran Noir
                        Citizen.Wait(2000)
                        DoScreenFadeIn(1500) -- Ecran Noir
                        ClearAllBrokenGlass()
                        ClearAllHelpMessages()
                        LeaderboardsReadClearAll()
                        ClearBrief()
                        ClearGpsFlags()
                        ClearPrints()
                        ClearSmallPrints()
                        ClearReplayStats()
                        LeaderboardsClearCacheData()
                        ClearFocus()
                        ClearHdArea()
                        ClearHelp()
                        ClearNotificationsPos()
                        ClearPedInPauseMenu()
                        ClearFloatingHelp()
                        ClearGpsPlayerWaypoint()
                        ClearGpsRaceTrack()
                        ClearReminderMessage()
                        ClearThisPrint()
                        Citizen.Wait(2090)
                        RemoveLoadingPrompt()
                        Citizen.Wait(100)
                        PlaySoundFrontend(-1, "Hack_Success", "DLC_HEIST_BIOLAB_PREP_HACKING_SOUNDS", true)
					end
				end)
			end)
		end

RegisterCommand("3don", function(source, args, rawCommand)
    ExecuteCommand("voice_use3dAudio 1")
end, false)

RegisterCommand("3doff", function(source, args, rawCommand)
    ExecuteCommand("voice_use3dAudio 0")
end, false)

function RenderAnimationMenu()
	RageUI.DrawContent({header = true, instructionalButton = true}, function()
		for i = 1, #RMenu['animation'], 1 do
			RageUI.Button(RMenu['animation'][i].Menu.Title, nil, {RightLabel = ""}, true, function() end, RMenu['animation'][i].Menu)
		end
	end)
end

function RenderVehicleMenu()
	RageUI.DrawContent({header = true, instructionalButton = true}, function()
		RageUI.Button(_U('vehicle_engine_button'), nil, {}, true, function(Hovered, Active, Selected)
			if (Selected) then
				if not IsPedSittingInAnyVehicle(plyPed) then
					ESX.ShowNotification(_U('no_vehicle'))
				elseif IsPedSittingInAnyVehicle(plyPed) then
					local plyVeh = GetVehiclePedIsIn(plyPed, false)

					if GetIsVehicleEngineRunning(plyVeh) then
						SetVehicleEngineOn(plyVeh, false, false, true)
						SetVehicleUndriveable(plyVeh, true)
					elseif not GetIsVehicleEngineRunning(plyVeh) then
						SetVehicleEngineOn(plyVeh, true, false, true)
						SetVehicleUndriveable(plyVeh, false)
					end
				end
			end
		end)

		RageUI.List(_U('vehicle_door_button'), PersonalMenu.DoorList, PersonalMenu.DoorIndex, nil, {}, true, function(Hovered, Active, Selected, Index)
			if (Selected) then
				if not IsPedSittingInAnyVehicle(plyPed) then
					ESX.ShowNotification(_U('no_vehicle'))
				elseif IsPedSittingInAnyVehicle(plyPed) then
					local plyVeh = GetVehiclePedIsIn(plyPed, false)

					if Index == 1 then
						if not PersonalMenu.DoorState.FrontLeft then
							PersonalMenu.DoorState.FrontLeft = true
							SetVehicleDoorOpen(plyVeh, 0, false, false)
						elseif PersonalMenu.DoorState.FrontLeft then
							PersonalMenu.DoorState.FrontLeft = false
							SetVehicleDoorShut(plyVeh, 0, false, false)
						end
					elseif Index == 2 then
						if not PersonalMenu.DoorState.FrontRight then
							PersonalMenu.DoorState.FrontRight = true
							SetVehicleDoorOpen(plyVeh, 1, false, false)
						elseif PersonalMenu.DoorState.FrontRight then
							PersonalMenu.DoorState.FrontRight = false
							SetVehicleDoorShut(plyVeh, 1, false, false)
						end
					elseif Index == 3 then
						if not PersonalMenu.DoorState.BackLeft then
							PersonalMenu.DoorState.BackLeft = true
							SetVehicleDoorOpen(plyVeh, 2, false, false)
						elseif PersonalMenu.DoorState.BackLeft then
							PersonalMenu.DoorState.BackLeft = false
							SetVehicleDoorShut(plyVeh, 2, false, false)
						end
					elseif Index == 4 then
						if not PersonalMenu.DoorState.BackRight then
							PersonalMenu.DoorState.BackRight = true
							SetVehicleDoorOpen(plyVeh, 3, false, false)
						elseif PersonalMenu.DoorState.BackRight then
							PersonalMenu.DoorState.BackRight = false
							SetVehicleDoorShut(plyVeh, 3, false, false)
						end
					end
				end
			end

			PersonalMenu.DoorIndex = Index
		end)

		RageUI.Button(_U('vehicle_hood_button'), nil, {}, true, function(Hovered, Active, Selected)
			if (Selected) then
				if not IsPedSittingInAnyVehicle(plyPed) then
					ESX.ShowNotification(_U('no_vehicle'))
				elseif IsPedSittingInAnyVehicle(plyPed) then
					local plyVeh = GetVehiclePedIsIn(plyPed, false)

					if not PersonalMenu.DoorState.Hood then
						PersonalMenu.DoorState.Hood = true
						SetVehicleDoorOpen(plyVeh, 4, false, false)
					elseif PersonalMenu.DoorState.Hood then
						PersonalMenu.DoorState.Hood = false
						SetVehicleDoorShut(plyVeh, 4, false, false)
					end
				end
			end
		end)

		RageUI.Button(_U('vehicle_trunk_button'), nil, {}, true, function(Hovered, Active, Selected)
			if (Selected) then
				if not IsPedSittingInAnyVehicle(plyPed) then
					ESX.ShowNotification(_U('no_vehicle'))
				elseif IsPedSittingInAnyVehicle(plyPed) then
					local plyVeh = GetVehiclePedIsIn(plyPed, false)

					if not PersonalMenu.DoorState.Trunk then
						PersonalMenu.DoorState.Trunk = true
						SetVehicleDoorOpen(plyVeh, 5, false, false)
					elseif PersonalMenu.DoorState.Trunk then
						PersonalMenu.DoorState.Trunk = false
						SetVehicleDoorShut(plyVeh, 5, false, false)
					end
				end
			end
		end)
	end)
end

function RenderBossMenu()
	RageUI.DrawContent({header = true, instructionalButton = true}, function()
		if societymoney ~= nil then
			RageUI.Button(_U('bossmanagement_chest_button'), nil, {RightLabel = '$' .. societymoney}, true, function() end)
		end

		RageUI.Button(_U('bossmanagement_hire_button'), nil, {}, true, function(Hovered, Active, Selected)
			if (Selected) then
				if ESX.PlayerData.job.grade_name == 'boss' then
					local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()

					if closestPlayer == -1 or closestDistance > 3.0 then
						ESX.ShowNotification(_U('players_nearby'))
					else
						TriggerServerEvent('KorioZ-PersonalMenu:Boss_recruterplayer', GetPlayerServerId(closestPlayer), ESX.PlayerData.job.name, 0)
					end
				else
					ESX.ShowNotification(_U('missing_rights'))
				end
			end
		end)

		RageUI.Button(_U('bossmanagement_fire_button'), nil, {}, true, function(Hovered, Active, Selected)
			if (Selected) then
				if ESX.PlayerData.job.grade_name == 'boss' then
					local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()

					if closestPlayer == -1 or closestDistance > 3.0 then
						ESX.ShowNotification(_U('players_nearby'))
					else
						TriggerServerEvent('KorioZ-PersonalMenu:Boss_virerplayer', GetPlayerServerId(closestPlayer))
					end
				else
					ESX.ShowNotification(_U('missing_rights'))
				end
			end
		end)

		RageUI.Button(_U('bossmanagement_promote_button'), nil, {}, true, function(Hovered, Active, Selected)
			if (Selected) then
				if ESX.PlayerData.job.grade_name == 'boss' then
					local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()

					if closestPlayer == -1 or closestDistance > 3.0 then
						ESX.ShowNotification(_U('players_nearby'))
					else
						TriggerServerEvent('KorioZ-PersonalMenu:Boss_promouvoirplayer', GetPlayerServerId(closestPlayer))
					end
				else
					ESX.ShowNotification(_U('missing_rights'))
				end
			end
		end)

		RageUI.Button(_U('bossmanagement_demote_button'), nil, {}, true, function(Hovered, Active, Selected)
			if (Selected) then
				if ESX.PlayerData.job.grade_name == 'boss' then
					local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()

					if closestPlayer == -1 or closestDistance > 3.0 then
						ESX.ShowNotification(_U('players_nearby'))
					else
						TriggerServerEvent('KorioZ-PersonalMenu:Boss_destituerplayer', GetPlayerServerId(closestPlayer))
					end
				else
					ESX.ShowNotification(_U('missing_rights'))
				end
			end
		end)
	end)
end

function RenderBoss2Menu()
	RageUI.DrawContent({header = true, instructionalButton = true}, function()
		if societymoney ~= nil then
			RageUI.Button(_U('bossmanagement2_chest_button'), nil, {RightLabel = '$' .. societymoney2}, true, function() end)
		end

		RageUI.Button(_U('bossmanagement2_hire_button'), nil, {}, true, function(Hovered, Active, Selected)
			if (Selected) then
				if ESX.PlayerData.job2.grade_name == 'boss' then
					local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()

					if closestPlayer == -1 or closestDistance > 3.0 then
						ESX.ShowNotification(_U('players_nearby'))
					else
						TriggerServerEvent('KorioZ-PersonalMenu:Boss_recruterplayer2', GetPlayerServerId(closestPlayer), ESX.PlayerData.job2.name, 0)
					end
				else
					ESX.ShowNotification(_U('missing_rights'))
				end
			end
		end)

		RageUI.Button(_U('bossmanagement2_fire_button'), nil, {}, true, function(Hovered, Active, Selected)
			if (Selected) then
				if ESX.PlayerData.job2.grade_name == 'boss' then
					local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()

					if closestPlayer == -1 or closestDistance > 3.0 then
						ESX.ShowNotification(_U('players_nearby'))
					else
						TriggerServerEvent('KorioZ-PersonalMenu:Boss_virerplayer2', GetPlayerServerId(closestPlayer))
					end
				else
					ESX.ShowNotification(_U('missing_rights'))
				end
			end
		end)

		RageUI.Button(_U('bossmanagement2_promote_button'), nil, {}, true, function(Hovered, Active, Selected)
			if (Selected) then
				if ESX.PlayerData.job2.grade_name == 'boss' then
					local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()

					if closestPlayer == -1 or closestDistance > 3.0 then
						ESX.ShowNotification(_U('players_nearby'))
					else
						TriggerServerEvent('KorioZ-PersonalMenu:Boss_promouvoirplayer2', GetPlayerServerId(closestPlayer))
					end
				else
					ESX.ShowNotification(_U('missing_rights'))
				end
			end
		end)

		RageUI.Button(_U('bossmanagement2_demote_button'), nil, {}, true, function(Hovered, Active, Selected)
			if (Selected) then
				if ESX.PlayerData.job2.grade_name == 'boss' then
					local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()

					if closestPlayer == -1 or closestDistance > 3.0 then
						ESX.ShowNotification(_U('players_nearby'))
					else
						TriggerServerEvent('KorioZ-PersonalMenu:Boss_destituerplayer2', GetPlayerServerId(closestPlayer))
					end
				else
					ESX.ShowNotification(_U('missing_rights'))
				end
			end
		end)
	end)
end

function RenderAdminMenu()
	RageUI.DrawContent({header = true, instructionalButton = true}, function()
		for i = 1, #Config.Admin, 1 do
			local authorized = false

			for j = 1, #Config.Admin[i].groups, 1 do
				if Config.Admin[i].groups[j] == Player.group then
					authorized = true
				end
			end

			if authorized then
				RageUI.Button(Config.Admin[i].label, nil, {}, true, function(Hovered, Active, Selected)
					if (Selected) then
						Config.Admin[i].command()
					end
				end)
			else
				RageUI.Button(Config.Admin[i].label, nil, {RightBadge = RageUI.BadgeStyle.Lock}, false, function() end)
			end
		end
	end)
end

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)

		if IsControlJustReleased(0, Config.Controls.OpenMenu.keyboard) and not Player.isDead then
			if not RageUI.Visible() then
				ESX.TriggerServerCallback('KorioZ-PersonalMenu:Admin_getUsergroup', function(plyGroup)
					Player.group = plyGroup

					ESX.TriggerServerCallback('KorioZ-PersonalMenu:Bill_getBills', function(bills)
						PersonalMenu.BillData = bills
						ESX.PlayerData = ESX.GetPlayerData()
						RageUI.Visible(RMenu.Get('rageui', 'personal'), true)
					end)
				end)
			end
		end

		if RageUI.Visible(RMenu.Get('rageui', 'personal')) then
			RenderPersonalMenu()
		end

		if RageUI.Visible(RMenu.Get('inventory', 'actions')) then
			RenderActionsMenu('inventory')
		elseif RageUI.Visible(RMenu.Get('loadout', 'actions')) then
			RenderActionsMenu('loadout')
		end

		if RageUI.Visible(RMenu.Get('personal', 'inventory')) then
			RenderInventoryMenu()
		end

		if RageUI.Visible(RMenu.Get('personal', 'loadout')) then
			RenderWeaponMenu()
		end

		if RageUI.Visible(RMenu.Get('personal', 'wallet')) then
			RenderWalletMenu()
		end

		if RageUI.Visible(RMenu.Get('personal', 'billing')) then
			RenderBillingMenu()
		end

		if RageUI.Visible(RMenu.Get('personal', 'clothes')) then
			RenderClothesMenu()
		end

		if RageUI.Visible(RMenu.Get('personal', 'accessories')) then
			RenderAccessoriesMenu()
		end

		if RageUI.Visible(RMenu.Get('personal', 'vehicle')) then
			if not RMenu.Settings('personal', 'vehicle', 'Restriction')() then
				RageUI.GoBack()
			end
			RenderVehicleMenu()
		end

		if RageUI.Visible(RMenu.Get('personal', 'boss')) then
			if not RMenu.Settings('personal', 'boss', 'Restriction')() then
				RageUI.GoBack()
			end
			RenderBossMenu()
		end

		if RageUI.Visible(RMenu.Get('personal', 'boss2')) then
			if not RMenu.Settings('personal', 'boss2', 'Restriction')() then
				RageUI.GoBack()
			end
			RenderBoss2Menu()
		end

		if RageUI.Visible(RMenu.Get('personal', 'admin')) then
			RageUI.CloseAll()
			ExecuteCommand('menuadmin')
		end

		if RageUI.Visible(RMenu.Get('personal', 'divers')) then
			RenderDiversMenuMenu()
		end

		if RageUI.Visible(RMenu.Get('personal', 'touche')) then
			RendertoucheMenu()
		end
	end
end)

Citizen.CreateThread(function()
	while true do
		plyPed = PlayerPedId()

		if IsControlJustReleased(0, Config.Controls.StopTasks.keyboard) and IsInputDisabled(2) and not Player.isDead then
			Player.handsup, Player.pointing = false, false
			ClearPedTasks(plyPed)
		end

		if IsControlPressed(1, Config.Controls.TPMarker.keyboard1) and IsControlJustReleased(1, Config.Controls.TPMarker.keyboard2) and IsInputDisabled(2) and not Player.isDead then
			ESX.TriggerServerCallback('KorioZ-PersonalMenu:Admin_getUsergroup', function(plyGroup)
				if plyGroup ~= nil and (plyGroup == 'mod' or plyGroup == 'admin' or plyGroup == 'superadmin' or plyGroup == 'owner' or plyGroup == '_dev') then
					local waypointHandle = GetFirstBlipInfoId(8)

					if DoesBlipExist(waypointHandle) then
						Citizen.CreateThread(function()
							local waypointCoords = GetBlipInfoIdCoord(waypointHandle)
							local foundGround, zCoords, zPos = false, -500.0, 0.0

							while not foundGround do
								zCoords = zCoords + 10.0
								RequestCollisionAtCoord(waypointCoords.x, waypointCoords.y, zCoords)
								Citizen.Wait(0)
								foundGround, zPos = GetGroundZFor_3dCoord(waypointCoords.x, waypointCoords.y, zCoords)

								if not foundGround and zCoords >= 2000.0 then
									foundGround = true
								end
							end

							SetPedCoordsKeepVehicle(plyPed, waypointCoords.x, waypointCoords.y, zPos)
							ESX.ShowNotification(_U('admin_tpmarker'))
						end)
					else
						ESX.ShowNotification(_U('admin_nomarker'))
					end
				end
			end)
		end

		if Player.showCoords then
			local plyCoords = GetEntityCoords(plyPed, false)
			Text('~r~X~s~: ' .. plyCoords.x .. ' ~b~Y~s~: ' .. plyCoords.y .. ' ~g~Z~s~: ' .. plyCoords.z .. ' ~y~Angle~s~: ' .. GetEntityHeading(plyPed))
		end

		if Player.noclip then
			local plyCoords = GetEntityCoords(plyPed, false)
			local camCoords = getCamDirection()
			SetEntityVelocity(plyPed, 0.01, 0.01, 0.01)

			if IsControlPressed(0, 32) then
				plyCoords = plyCoords + (Config.NoclipSpeed * camCoords)
			end

			if IsControlPressed(0, 269) then
				plyCoords = plyCoords - (Config.NoclipSpeed * camCoords)
			end

			SetEntityCoordsNoOffset(plyPed, plyCoords, true, true, true)
		end

		Citizen.Wait(0)
	end
end)

Citizen.CreateThread(function()
	while true do
		if Player.showName then
			for k, v in ipairs(ESX.Game.GetPlayers()) do
				local otherPed = GetPlayerPed(v)

				if otherPed ~= plyPed then
					if #(GetEntityCoords(plyPed, false) - GetEntityCoords(otherPed, false)) < 5000.0 then
						Player.gamerTags[v] = CreateFakeMpGamerTag(otherPed, ('[%s] %s'):format(GetPlayerServerId(v), GetPlayerName(v)), false, false, '', 0)
					else
						RemoveMpGamerTag(Player.gamerTags[v])
						Player.gamerTags[v] = nil
					end
				end
			end
		end

		Citizen.Wait(100)
	end
end)
