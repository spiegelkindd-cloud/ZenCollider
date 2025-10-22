(
// Inicia el servidor de audio.
s.boot;
s.waitForBoot {

	var reverbBus;

	// ===================================================================
	// 1. CONFIGURACIÓN DEL SONIDO (MODIFICAR AQUÍ)
	// ===================================================================

	var useMidiNote = true;
	var pitchMidi = 60; // Nota Do central (C4)
	var pitchHz = 256.0;
	var minAmp = 0.25;
	var maxAmp = 0.45;
	var minTimeBetween = 2.0;
	var maxTimeBetween = 5.0;

	// ===================================================================
	// 2. DEFINICIÓN DE LOS SINTETIZADORES (SynthDefs)
	// ===================================================================

	reverbBus = Bus.audio(s, 2);

	SynthDef(\reverb, {
		arg inBus, outBus = 0, mix = 0.3, room = 0.7, damp = 0.6;
		var input, wetSignal;
		input = In.ar(inBus, 2);
		wetSignal = JPverb.ar(input, t60: 4.0, damp: damp, size: room);
		Out.ar(outBus, XFade2.ar(input, wetSignal, mix * 2 - 1));
	}).add;

	SynthDef(\singingBowl, {
		arg out = 0, freq = 200, amp = 0.3, pan = 0, attack = 0.01, decay = 8, sustain = 12;
		var sig, env;
		env = EnvGen.kr(Env.perc(attack, decay + sustain, amp, -4), doneAction: 2);
		sig = Mix.new([
			SinOsc.ar(freq),
			SinOsc.ar(freq * 2.75, mul: 0.4),
			SinOsc.ar(freq * 5.4, mul: 0.25),
			SinOsc.ar(freq * 9.2, mul: 0.1)
		]);
		sig = sig * env;
		Out.ar(out, Pan2.ar(sig, pan));
		Out.ar(reverbBus, Pan2.ar(sig, pan));
	}).add;

	s.sync; // Espera a que los SynthDefs se carguen.

	// ===================================================================
	// 3. LÓGICA PRINCIPAL DE LA MEDITACIÓN (Routine)
	// ===================================================================

	Routine({
		var finalFreq, reverbSynth;
		var window, textField, okButton;

		reverbSynth = Synth(\reverb, [\inBus, reverbBus]);
		finalFreq = if(useMidiNote, pitchMidi.midicps, pitchHz);

		"--------------------------------------------------".postln;
		"Bienvenido. Por favor, introduce la duración en la ventana emergente.".postln;

		window = Window("Meditación", Rect(800, 400, 320, 90)).front;
		textField = TextField(window, Rect(20, 40, 200, 24)).string_("15");
		StaticText(window, Rect(20, 10, 280, 24)).string_("Duración de la meditación (minutos):");

		okButton = Button(window, Rect(230, 40, 70, 24))
		.states_([ ["Iniciar"] ])
		.action_({
			var durationMinutes, durationSeconds, numIntervals;
			var countdown = 30;
			var interval = 5 * 60;

			durationMinutes = textField.string.asFloat;
			window.close;

			if(durationMinutes.notNil and: { durationMinutes > 0 }) {
				durationSeconds = durationMinutes * 60;
				numIntervals = (durationSeconds / interval).ceil;

				"Gracias. La meditación durará".postln;
				durationMinutes.post; " minutos.".postln;
				"La cuenta regresiva de 30 segundos comienza AHORA.".postln;
				"--------------------------------------------------".postln;

				Routine({
					// CORRECCIÓN: Todas las variables se declaran al inicio de la Routine.
					var startOfInterval, timeElapsedInInterval, waitTime;

					countdown.do({ |i| (countdown - i).post; "... ".post; 1.wait; });
					"Comenzamos.".postln;

					numIntervals.do({ |i|
						startOfInterval = TempoClock.beats;

						"Iniciando secuencia de campanadas".post;
						if(i > 0) { " (minuto ".post; i * 5; ")".post; };
						"".postln;

						3.do({
							Synth(\singingBowl, [\freq, finalFreq, \amp, rrand(minAmp, maxAmp), \pan, rrand(-0.5, 0.5)]);
							rrand(minTimeBetween, maxTimeBetween).wait;
						});

						// CORRECCIÓN: Ahora solo asignamos valores a las variables ya declaradas.
						timeElapsedInInterval = TempoClock.beats - startOfInterval;
						waitTime = interval - timeElapsedInInterval;

						if (waitTime > 0) {
							if (i < (numIntervals - 1)) {
								"Las próximas campanadas sonarán en 5 minutos...".postln;
							};
							waitTime.wait;
						};
					});

					"Campanada final.".postln;
					Synth(\singingBowl, [\freq, finalFreq, \amp, maxAmp, \pan, 0]);
					(minTimeBetween).wait;

					"--------------------------------------------------".postln;
					"La sesión de meditación ha terminado.".postln;
					reverbSynth.free;
					"Namasté ☸︎".postln;
					"--------------------------------------------------".postln;
				}).play(AppClock);

			} {
				"Entrada inválida o cancelada. Por favor, ejecuta el script de nuevo.".postln;
				reverbSynth.free;
			}
		});

		window.onClose_({ okButton.action = nil; });

	}).play(AppClock);
};
)
