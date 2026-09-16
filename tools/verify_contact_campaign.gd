extends SceneTree
var game
const MediaPack = preload("res://scripts/media.gd")
func _initialize() -> void:call_deferred("run")
func run() -> void:
	if not MediaPack.media_complete(): MediaPack.stand_in_film = "res://tools/test_media/stand_in_film.ogv"
	game=load("res://main.tscn").instantiate();game.settings_path="user://contact-campaign.cfg";root.add_child(game)
	await process_frame;game.save_enabled=false;game.set_process(false);game.world.set_process(false)
	game.checkpoints.set_process(false);game.auto_dodges=false;game.finale.movies_enabled=false;game.demo=true
	var failures:=0
	for assist in [false,true]:
		game.steering_assist=assist;game.relaxed_hazards=assist;game.rng.seed=72611;game.start_chase()
		var stages: Array[int]=[]
		for frame in range(48000):
			if game.mode==game.Mode.UPGRADE:
				stages.append(game.stage);print("STAGE ",game.stage," health ",game.health)
				game.choose_upgrade(0 if game.health<80 else 1);game.checkpoints.complete()
			if game.mode==game.Mode.RUNNING:
				if game.charge>=100:game.deploy_probe()
				var hits: int=game.hits
				game._simulate(1.0/60.0)
				if hits!=game.hits:print("HIT at ",game.elapsed," stage ",game.stage," lane ",game.player_x," hull ",game.health," kind ",game.debris.filter(func(d):return d.has("impact_age") and d.impact_age==0.0))
			if game.mode==game.Mode.VORTEX:game.finale.step(1.0/60.0)
			if game.mode in [game.Mode.RESULTS,game.Mode.CRASH]:break
		var won: bool=stages==[1,2,3,4,5,6,7] and game.mode==game.Mode.RESULTS and game.result_title=="INTO THE VORTEX"
		if not won:failures+=1
		print("PASS: " if won else "FAIL: ","complete playable campaign, assist=",assist," health=",game.health," hits=",game.hits)
	print("CONTACT_CAMPAIGN_TESTS 2 checks; ",failures," failures")
	game.queue_free();await process_frame;quit(1 if failures else 0)
