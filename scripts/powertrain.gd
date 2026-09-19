extends RefCounted
# Arcade powertrain: speed remains the campaign's mph display, not SI dynamics.
# Small bounded substeps keep torque response consistent across render rates.
var throttle := 0.0
var load := 0.0
var rpm := 2400.0
var gear := 3
var shift_time := 0.0
var acceleration := 0.0
var shifts := 0
## Mateo Garage chase setup; 1.0 is the original tune.
var accel_factor := 1.0
const LIMITS := [0.0, 45.0, 85.0, 130.0, 175.0, 220.0, 280.0]

func reset(speed: float) -> void:
	throttle = 0.0; load = 0.0; acceleration = 0.0; shift_time = 0.0; shifts = 0
	gear = 1
	while gear < 6 and speed > LIMITS[gear]: gear += 1
	rpm = clampf(1100.0 + speed / LIMITS[gear] * 3100.0, 850.0, 5300.0)

func step(dt: float, speed: float, target: float, boost: bool, brake: bool, grounded: bool, dirt: float, grade: float) -> float:
	var remaining := maxf(dt, 0.0)
	while remaining > 0.000001:
		var h := minf(remaining, 1.0 / 120.0)
		remaining -= h
		shift_time = maxf(0.0, shift_time - h)
		if grounded and shift_time == 0.0:
			var next := gear
			if gear < 6 and speed > LIMITS[gear]: next += 1
			elif gear > 1 and speed < LIMITS[gear-1] - 12.0: next -= 1
			if next != gear:
				gear = next; shift_time = 0.23; shifts += 1
		var demand := 0.0 if brake else clampf((target - speed) / 22.0 + 0.24, 0.0, 1.0)
		throttle = lerpf(throttle, demand, 1.0 - exp(-h * (3.2 if demand > throttle else 9.0)))
		var coupling := 0.24 if shift_time > 0.0 else 1.0
		load = lerpf(load, throttle * coupling * (1.0 if grounded else 0.16), 1.0 - exp(-h * 6.0))
		var desired := clampf((target - speed) * 2.0, -62.0, (51.0 if boost else 33.0) * throttle * coupling * accel_factor)
		if brake: desired = -118.0 if speed > target else 0.0
		elif grounded:
			desired -= maxf(0.0, grade) * 13.0 + dirt * throttle * 2.5
		if not grounded: desired = -1.8 # No ground thrust or road braking in flight.
		acceleration = lerpf(acceleration, desired, 1.0 - exp(-h * (10.0 if brake else 5.0)))
		if not grounded: acceleration = minf(acceleration, -1.8)
		speed = maxf(0.0, speed + acceleration * h)
		var rev_target: float = 1100.0 + speed / LIMITS[gear] * 3100.0 + throttle * 520.0
		if not grounded: rev_target = 3200.0 + throttle * 2400.0
		rpm = lerpf(rpm, clampf(rev_target, 850.0, 5700.0), 1.0 - exp(-h * 5.0))
	return speed
