/obj/machinery/atmospherics/unary/vent_pump
	icon = 'icons/obj/atmospherics/vent_pump.dmi'
	icon_state = "off"

	name = "Air Vent"
	desc = "Has a valve and pump attached to it"

	level = 1

	high_volume
		name = "Large Air Vent"

		New()
			..()

			air_contents.volume = 1000

	var/on = 1
	var/pump_direction = 1 //0 = siphoning, 1 = releasing

	var/external_pressure_bound = ONE_ATMOSPHERE
	var/internal_pressure_bound = 0

	var/volume_rate = 1000

	var/pressure_checks = 1
	//1: Do not pass external_pressure_bound
	//2: Do not pass internal_pressure_bound
	//3: Do not pass either

	update_icon()
		if(on&&node)
			if(pump_direction)
				icon_state = "[level == 1 && istype(loc, /turf/simulated) ? "h" : "" ]out"
			else
				icon_state = "[level == 1 && istype(loc, /turf/simulated) ? "h" : "" ]in"
		else
			icon_state = "[level == 1 && istype(loc, /turf/simulated) ? "h" : "" ]off"
			on = 0

		return

	process()
		..()
		if(!on)
			return 0

		var/datum/gas_mixture/environment = loc.return_air(1)
		//var/environment_pressure = environment.return_pressure()

		/*if(pump_direction) //internal -> external
			var/pressure_delta = 10000

			if(pressure_checks&1)
				pressure_delta = min(pressure_delta, (external_pressure_bound - environment_pressure))
			if(pressure_checks&2)
				pressure_delta = min(pressure_delta, (air_contents.return_pressure() - internal_pressure_bound))

			if(pressure_delta > 0)
				if(air_contents.temperature > 0)
					var/transfer_moles = pressure_delta*environment.volume/(air_contents.temperature * R_IDEAL_GAS_EQUATION)

					var/datum/gas_mixture/removed = air_contents.remove(transfer_moles)

					loc.assume_air(removed)

					if(network)
						network.update = 1

		else //external -> internal
			var/pressure_delta = 10000

			if(pressure_checks&1)
				pressure_delta = min(pressure_delta, (environment_pressure - external_pressure_bound))
			if(pressure_checks&2)
				pressure_delta = min(pressure_delta, (internal_pressure_bound - air_contents.return_pressure()))

			if(pressure_delta > 0)
				if(environment.temperature > 0)
					var/transfer_moles = pressure_delta*air_contents.volume/(environment.temperature * R_IDEAL_GAS_EQUATION)

					var/datum/gas_mixture/removed = loc.remove_air(transfer_moles)

					air_contents.merge(removed)

					if(network)
						network.update = 1

		return 1*/
		if(pump_direction)
			//Can not have a pressure delta that would cause environment pressure > tank pressure
			var/pressure_delta = 10000
			var/environment_pressure = environment.return_pressure()
			if(pressure_checks&1)
				pressure_delta = min(pressure_delta, (external_pressure_bound - environment_pressure))
			if(pressure_checks&2)
				pressure_delta = min(pressure_delta, (air_contents.return_pressure() - internal_pressure_bound))
			if(pressure_delta < 0)
				return 1
			var/transfer_moles = 0
			if(air_contents.temperature > 0)
				transfer_moles = min(1, volume_rate/environment.volume)*environment.total_moles

				//Actually transfer the gas
				var/datum/gas_mixture/removed = air_contents.remove(transfer_moles)

				if(removed) loc.assume_air(removed)
				if (network)
					network.update = 1
		else
			//Can not have a pressure delta that would cause environment pressure > tank pressure
			var/pressure_delta = 10000
			var/environment_pressure = environment.return_pressure()
			if(pressure_checks&1)
				pressure_delta = min(pressure_delta, (environment_pressure - external_pressure_bound))
			if(pressure_checks&2)
				pressure_delta = min(pressure_delta, (internal_pressure_bound - air_contents.return_pressure()))
			var/transfer_moles = 0
			if(environment.temperature > 0)
				transfer_moles = min(1, volume_rate/environment.volume)*environment.total_moles

				//Actually transfer the gas
				var/datum/gas_mixture/removed

				removed = loc.remove_air(transfer_moles)

				if(removed) air_contents.merge(removed)
				if (network)
					network.update = 1

	//Radio remote control

	proc
		set_frequency(new_frequency)
			radio_controller.remove_object(src, "[frequency]")
			frequency = new_frequency
			if(frequency)
				radio_connection = radio_controller.add_object(src, "[frequency]")

		broadcast_status()
			if(!radio_connection)
				return 0

			var/datum/signal/signal = new
			signal.transmission_method = 1 //radio signal
			signal.source = src

			signal.data["tag"] = id
			signal.data["device"] = "AVP"
			signal.data["power"] = on?("on"):("off")
			signal.data["direction"] = pump_direction?("release"):("siphon")
			signal.data["checks"] = pressure_checks
			signal.data["internal"] = internal_pressure_bound
			signal.data["external"] = external_pressure_bound

			radio_connection.post_signal(src, signal)

			return 1

	var/frequency = 0
	var/id = null
	var/datum/radio_frequency/radio_connection

	initialize()
		..()
		if(frequency)
			set_frequency(frequency)
		update_icon()

	receive_signal(datum/signal/signal)
		if(signal.data["tag"] && (signal.data["tag"] != id))
			return 0

		switch(signal.data["command"])
			if("power_on")
				on = 1

			if("power_off")
				on = 0

			if("power_toggle")
				on = !on

			if("set_direction")
				var/number = text2num(signal.data["parameter"])
				if(number > 0.5)
					pump_direction = 1
				else
					pump_direction = 0

			if("purge")
				pressure_checks &= ~1
				pump_direction = 0

			if("stabalize")
				pressure_checks |= 1
				pump_direction = 1

			if("set_checks")
				var/number = round(text2num(signal.data["parameter"]),1)
				pressure_checks = number

			if("set_internal_pressure")
				var/number = text2num(signal.data["parameter"])
				number = min(max(number, 0), ONE_ATMOSPHERE*50)

				internal_pressure_bound = number

			if("set_external_pressure")
				var/number = text2num(signal.data["parameter"])
				number = min(max(number, 0), ONE_ATMOSPHERE*50)

				external_pressure_bound = number

		if(signal.data["tag"])
			spawn(5 * tick_multiplier) broadcast_status()

	hide(var/i) //to make the little pipe section invisible, the icon changes.
		if(on&&node)
			if(pump_direction)
				icon_state = "[i == 1 && istype(loc, /turf/simulated) ? "h" : "" ]out"
			else
				icon_state = "[i == 1 && istype(loc, /turf/simulated) ? "h" : "" ]in"
		else
			icon_state = "[i == 1 && istype(loc, /turf/simulated) ? "h" : "" ]off"
			on = 0
		return

/obj/machinery/atmospherics/unary/vent
	icon = 'icons/obj/atmospherics/vent_pump.dmi'
	icon_state = "equal"

	name = "Air Vent"
	desc = "Has a valve and pump attached to it"

	level = 1

	New()
		..()

		air_contents.volume = 500
		layer = TURF_LAYER

	high_volume
		name = "Large Air Vent"

		New()
			..()

			air_contents.volume = 1500

	var/on = 1
	var/pump_direction = 0 //0 = equalizing, 1 = releasing, -1 = siphoning

	var/external_pressure_bound = ONE_ATMOSPHERE
	var/internal_pressure_bound = 4000

	var/pressure_checks = 0
	//1: Do not pass external_pressure_bound
	//2: Do not pass internal_pressure_bound
	//3: Do not pass either

	var/debug_info = 0

	update_icon()
		icon_state = "[level == 1 && istype(loc, /turf/simulated) ? "h" : "" ]off"
		if(on&&node)
			if(pump_direction > 0)
				icon_state = "[level == 1 && istype(loc, /turf/simulated) ? "h" : "" ]out"
			else if(pump_direction < 0)
				icon_state = "[level == 1 && istype(loc, /turf/simulated) ? "h" : "" ]in"
			else
				icon_state = "[level == 1 && istype(loc, /turf/simulated) ? "h" : "" ]equal"
		else
			icon_state = "[level == 1 && istype(loc, /turf/simulated) ? "h" : "" ]off"
			if(!node) on = 0

		return

	process()
		..()
		if(!on)
			return 0
		switch(pump_direction)
			if(0)
				var/datum/gas_mixture/environment = loc.return_air(1)
				var/environment_pressure = environment.return_pressure()
				var/internal_pressure = air_contents.return_pressure()

				if(pressure_checks & 1)
					if(debug_info) world << "<b>Pressure Check: External</b>"
					if(environment_pressure >= external_pressure_bound)
						if(debug_info) world << "\red Failed! [environment_pressure] > [external_pressure_bound]"
						return
				if(pressure_checks & 2)
					if(debug_info) world << "<b>Pressure Check: Internal</b>"
					if(internal_pressure >= internal_pressure_bound)
						if(debug_info) world << "\red Failed! [internal_pressure] > [internal_pressure_bound]"
						return

				var/turf/simulated/T = loc
				var
					used_pressure = max(environment_pressure,internal_pressure)
					used_temperature = TCMB
				if(used_pressure == environment_pressure)
					if(debug_info) world << "Used Pressure: Environment Pressure ([environment_pressure])"
					used_temperature = air_contents.temperature
				else
					if(debug_info) world << "Used Pressure: Internal Pressure ([internal_pressure])"
					used_temperature = environment.temperature
				var/transfer_moles = used_pressure*air_contents.volume/(max(used_temperature,TCMB) * R_IDEAL_GAS_EQUATION)

				if(debug_info) world << "Transfer Amount [transfer_moles] Moles"

				var/datum/gas_mixture/intake = T.remove_air(transfer_moles)
				var/datum/gas_mixture/env = air_contents.remove(transfer_moles)

				if(env && intake)
					equalize_gases(list(env,intake))
					//env.merge(intake)
					//intake = env.remove(0.5*env.total_moles)
					if(intake) T.assume_air(intake)
					air_contents.merge(env)
			if(1)
				var/datum/gas_mixture/environment = loc.return_air(1)
			//	var/environment_pressure = environment.return_pressure()
				if(pressure_checks & 1)
					if(environment.return_pressure() >= external_pressure_bound) return

				var/turf/simulated/T = loc
				var
					used_pressure = air_contents.return_pressure()//min(air_contents.return_pressure(),external_pressure_bound)
					used_temperature = environment.temperature

				var/transfer_moles = used_pressure*air_contents.volume/(max(used_temperature,TCMB) * R_IDEAL_GAS_EQUATION)

				var/datum/gas_mixture/env = air_contents.remove(transfer_moles)

				if(env) T.assume_air(env)
			if(-1)
				if(pressure_checks & 2)
					if(air_contents.return_pressure() >= internal_pressure_bound) return

				var/datum/gas_mixture/environment = loc.return_air(1)
				var/environment_pressure = environment.return_pressure()

				var/turf/simulated/T = loc
				var
					used_pressure = environment_pressure
					used_temperature = air_contents.temperature
				var/transfer_moles = used_pressure*air_contents.volume/(max(used_temperature,TCMB) * R_IDEAL_GAS_EQUATION)

				var/datum/gas_mixture/env = T.remove_air(transfer_moles)

				if(env) air_contents.merge(env)

		/*if(T.zone)
			var
				removed_o2 = T.zone.add_oxygen(-transfer_moles)
				removed_n2 = T.zone.add_nitrogen(-transfer_moles)
				removed_co2 = T.zone.add_co2(-transfer_moles)

			var/datum/gas_mixture/combined = air_contents.remove(transfer_moles)

			combined.oxygen += removed_o2
			combined.nitrogen += removed_n2
			combined.carbon_dioxide += removed_co2

			var/datum/gas_mixture/zone_portion = combined.remove(combined.total_moles*0.5)
			T.zone.add_oxygen(zone_portion.oxygen)
			T.zone.add_nitrogen(zone_portion.nitrogen)
			T.zone.add_co2(zone_portion.carbon_dioxide)
			air_contents.merge(combined)*/



		if(network)
			network.update = 1

		/*if(pump_direction) //internal -> external
			var/pressure_delta = 10000

			if(pressure_checks&1)
				pressure_delta = min(pressure_delta, (external_pressure_bound - environment_pressure))
			if(pressure_checks&2)
				pressure_delta = min(pressure_delta, (air_contents.return_pressure() - internal_pressure_bound))

			if(pressure_delta > 0)
				if(air_contents.temperature > 0)
					var/transfer_moles = pressure_delta*environment.volume/(air_contents.temperature * R_IDEAL_GAS_EQUATION)

					var/datum/gas_mixture/removed = air_contents.remove(transfer_moles)

					loc.assume_air(removed)

					if(network)
						network.update = 1

		else //external -> internal
			var/pressure_delta = 10000

			if(pressure_checks&1)
				pressure_delta = min(pressure_delta, (environment_pressure - external_pressure_bound))
			if(pressure_checks&2)
				pressure_delta = min(pressure_delta, (internal_pressure_bound - air_contents.return_pressure()))

			if(pressure_delta > 0)
				if(environment.temperature > 0)
					var/transfer_moles = pressure_delta*air_contents.volume/(environment.temperature * R_IDEAL_GAS_EQUATION)

					var/datum/gas_mixture/removed = loc.remove_air(transfer_moles)

					air_contents.merge(removed)

					if(network)
						network.update = 1*/

		return 1

	hide(var/i) //to make the little pipe section invisible, the icon changes.
		icon_state = "[i == 1 && istype(loc, /turf/simulated) ? "h" : "" ]off"
		return
/obj/machinery/atmospherics/unary/vent_filter
	icon = 'icons/obj/atmospherics/pipe_vent.dmi'
	icon_state = "intact"

	name = "Vent"
	desc = "A large air vent"
	level = 1
	initialize_directions = 2
	New()
		..()
		layer = 2
		air_contents.volume = 500

	high_volume
		name = "Large Air Vent"

		New()
			..()
			update_icon()
			air_contents.volume = 1500
	attack_alien(mob/user as mob)
		if(user in range(1,src))
			for(var/mob/A in viewers())
				A << "[user] climbs into the [src]"
			user.loc = src
			burst = 1
		update_icon()
	relaymove(mob/user as mob,dirc)
		..()
		if(user in src.contents)
			for(var/mob/A in viewers())
				A << "[user] bursts from the [src]"
			user.loc = src.loc
			burst = 1
			update_icon()
	var/burst = 0
	var/on = 1
	var/pump_direction = 0 //0 = equalizing, 1 = releasing, -1 = siphoning
	var/toxins_fil = 1
	var/o2_fil = 0
	var/co2_fil = 1
	var/trace_fil = 1
	var/no_fil = 0
	var/external_pressure_bound = ONE_ATMOSPHERE
	var/internal_pressure_bound = 4000

	var/panic_fill = 0		//Strumpetplaya - Added this as quick fix to get alarm interfaces working again.
	var/panic_filling = 0	//This too.
	var/volume_rate = 1000

	var/pressure_checks = 1
	//1: Do not pass external_pressure_bound
	//2: Do not pass internal_pressure_bound
	//3: Do not pass either

	var/debug_info = 0

	update_icon()
		if(burst)
			icon_state = "burst"
		//if(src.loc
		//var/turf/locT = src.loc
		//if(locT.zone.space_connections.len >= 1)
		//	return
	//	icon_state = "[level == 1 && istype(loc, /turf/simulated) ? "h" : "" ]off"
	//	if(on&&node)
	//		icon_state = "[level == 1 && istype(loc, /turf/simulated) ? "h" : "" ]out"

		return

	process()
	//	..()
		update_icon()
		if(!on)
			return 0
		var/datum/gas_mixture/environment = loc.return_air(1)

		var/list/filter = new()
		var/toxins_fil = 1
		var/o2_fil = 0
		var/co2_fil = 1
		var/no_fil = 0
		if(toxins_fil)
			filter += "phoron"
		if(o2_fil)
			filter += "oxygen"
		if(co2_fil)
			filter += "carbon_dioxide"
		if(no_fil)
			filter += "nitrogen"
		var/datum/gas_mixture/source = null
		var/datum/gas_mixture/output = null
		switch(pump_direction)
			if(0)
				if(environment.return_pressure() < ONE_ATMOSPHERE*0.95)
					return
				source = air_contents
				output = environment
			if(1)
				source = air_contents
				output = environment
			if(-1)
				source = environment
				output = air_contents
		var/transfer_moles = min(1, volume_rate/source.volume)*source.total_moles
///proc/filter_gas(var/obj/machinery/M, var/list/filtering, var/datum/gas_mixture/source, var/datum/gas_mixture/sink_filtered, var/datum/gas_mixture/sink_clean, var/total_transfer_moles = null, var/available_power = null)
		filter_gas_multi(src,filter,source,output,transfer_moles) // TODO:2015 IX
		if(network)
			network.update = 1
		return 1

	hide(var/i) //to make the little pipe section invisible, the icon changes.
		icon_state = "[i == 1 && istype(loc, /turf/simulated) ? "h" : "" ]off"
		return
