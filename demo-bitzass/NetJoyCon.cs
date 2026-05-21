using Godot;
using System;
using System.Linq;
using HidSharp;
using System.Text;
using wtf.cluster.JoyCon;
using wtf.cluster.JoyCon.Calibration;
using wtf.cluster.JoyCon.ExtraData;
using wtf.cluster.JoyCon.HomeLed;
using wtf.cluster.JoyCon.InputReports;
using wtf.cluster.JoyCon.Rumble;
using System.Threading.Tasks;
using System.Collections.Generic;
using wtf.cluster.JoyCon.InputData;

[GlobalClass]
public partial class NetJoyCon : Node3D
{
	private void AttachHandler(JoyCon jc)
	{
		jc.ReportReceived -= OnReportReceived; // prevent stacking
		jc.ReportReceived += OnReportReceived;
	}
	private Task OnReportReceived(JoyCon jc, IJoyConReport input)
	{
		if (!joyConNodes.ContainsKey(jc))
			return Task.CompletedTask;

		if (input is InputFullWithImu fullReport)
		{
			// ✅ readiness (only first time)
			if (readySignals.ContainsKey(jc) && !readySignals[jc].Task.IsCompleted)
			{
				GD.Print($"First IMU packet received for {joyConNodes[jc].Name}");
				readySignals[jc].TrySetResult(true);
			}

			// ⚠️ make sure calibration exists before using it
			if (!calibration.ContainsKey(jc) || calibration[jc] == null)
				return Task.CompletedTask;

			var calib = calibration[jc];
			if (calib?.ImuCalibration == null)
				return Task.CompletedTask;

			// ================= BUTTONS =================
			var buttons = fullReport.Buttons;

			var buttonStates = new Godot.Collections.Dictionary
			{
				{ "a", buttons.A },
				{ "b", buttons.B },
				{ "x", buttons.X },
				{ "y", buttons.Y },
				{ "up", buttons.Up },
				{ "down", buttons.Down },
				{ "left", buttons.Left },
				{ "right", buttons.Right },
				{ "l", buttons.L },
				{ "r", buttons.R },
				{ "zl", buttons.ZL },
				{ "zr", buttons.ZR },
				{ "plus", buttons.Plus },
				{ "minus", buttons.Minus },
				{ "home", buttons.Home },
				{ "capture", buttons.Capture }
			};

			joyConNodes[jc].CallDeferred("set_meta", "buttons", buttonStates);

			// ================= STICK =================
			IStickPosition stickPos = leftJoyCons.Contains(jc)
				? fullReport.LeftStick
				: fullReport.RightStick;

			float x = (stickPos.X - 2048f) / 2048f * 2f;
			float y = (stickPos.Y - 2048f) / 2048f * 2f;

			var stickDict = new Godot.Collections.Dictionary
			{
				{ "stick", new Vector2(x, y) }
			};

			joyConNodes[jc].CallDeferred("set_meta", "stick", stickDict);

			// ================= IMU =================
			var imu = fullReport.Imu;

			Vector3 acc = Vector3.Zero;
			Vector3 gyro = Vector3.Zero;

			for (int i = 0; i < imu.Frames.Count; i++)
			{
				var frame = imu.Frames[i].GetCalibrated(calib.ImuCalibration);

				acc += new Vector3(
					(float)frame.AccelX,
					(float)frame.AccelY,
					(float)frame.AccelZ
				);

				gyro += new Vector3(
					(float)frame.GyroX,
					(float)frame.GyroY,
					(float)frame.GyroZ
				);
			}

			acc /= imu.Frames.Count;
			gyro /= imu.Frames.Count;

			joyConNodes[jc].CallDeferred("set_meta", "acc", acc);
			joyConNodes[jc].CallDeferred("set_meta", "gyro_s", gyro);
		}

		return Task.CompletedTask;
	}
	Dictionary<JoyCon, TaskCompletionSource<bool>> readySignals = new();
	float startTime;
	#nullable enable
	HidDevice? device = null;
	Dictionary<JoyCon, CalibrationData?> calibration = new Dictionary<JoyCon, CalibrationData?>();
	#nullable disable
	DeviceList list;

	List<JoyCon> rightJoyCons = new List<JoyCon>();
	List<JoyCon> leftJoyCons = new List<JoyCon>();

	Dictionary<JoyCon, Godot.Node3D> joyConNodes = new Dictionary<JoyCon, Godot.Node3D>();
	// Use nodes, because gd classes can't be used within c#. Use set_metat, hacky but works

	Dictionary<JoyCon, StickParametersSet> stickParameters = new Dictionary<JoyCon, StickParametersSet>();

	Dictionary<JoyCon, Vector3> joyConRawAccData = new Dictionary<JoyCon, Vector3>();
	Dictionary<JoyCon, Vector3> joyConRawGyroData = new Dictionary<JoyCon, Vector3>();

	Dictionary<JoyCon, Vector3> joyConTranslatedAccData = new Dictionary<JoyCon, Vector3>();
	Dictionary<JoyCon, Vector3> joyConTranslatedGyroData = new Dictionary<JoyCon, Vector3>();   

	Dictionary<JoyCon, Quaternion> joyConTotalRotation = new Dictionary<JoyCon, Quaternion>();

	public override void _Ready()
	{
		startTime = Time.GetTicksMsec();
		list = DeviceList.Local;
		if (OperatingSystem.IsWindows())
		{
			// Get all devices developed by Nintendo by vendor ID
			var nintendos = list.GetHidDevices(0x057e);
			foreach(var nintendo in nintendos)
			{
				if (nintendo.GetMaxInputReportLength() < 20)
					continue;
				// Joy-Con has 0x2006 or 0x2007 product ID
				Godot.GD.Print($"Found device: {nintendo.ProductName} (PID: {nintendo.ProductID:X4})");
				if ((nintendo.ProductID == 0x2007))
				{
					rightJoyCons.Add(new JoyCon(nintendo));
					joyConRawAccData[rightJoyCons.Last()] = new Vector3();
					joyConRawGyroData[rightJoyCons.Last()] = new Vector3();
					joyConTranslatedAccData[rightJoyCons.Last()] = new Vector3();
					joyConTranslatedGyroData[rightJoyCons.Last()] = new Vector3();
					joyConTotalRotation[rightJoyCons.Last()] = Quaternion.Identity;
					var myGDScript = GD.Load<GDScript>("res://scripts/joy_con.gd");
					Node3D joyConNode = (Node3D)myGDScript.New();
					joyConNode.Set("is_right_joycon", true);
					joyConNode.Name = $"JoyCon_Right_{rightJoyCons.Count}";
					AddChild(joyConNode);
					joyConNodes[rightJoyCons.Last()] = joyConNode;
					Godot.GD.Print($"Added right Joy-Con: {joyConNode.Name}");
					// Add a visual representation of the Joy-Con (e.g., a MeshInstance3D with a model of the Joy-Con)
					//MeshInstance3D meshInstance = new MeshInstance3D();
					//Mesh mesh = new BoxMesh();
					//meshInstance.Mesh = mesh;
					//joyConNode.AddChild(meshInstance);
				}
				else if ((nintendo.ProductID == 0x2006))
				{
					leftJoyCons.Add(new JoyCon(nintendo));
					joyConRawAccData[leftJoyCons.Last()] = new Vector3();
					joyConRawGyroData[leftJoyCons.Last()] = new Vector3();
					joyConTranslatedAccData[leftJoyCons.Last()] = new Vector3();
					joyConTranslatedGyroData[leftJoyCons.Last()] = new Vector3();
					joyConTotalRotation[leftJoyCons.Last()] = Quaternion.Identity;
					var myGDScript = GD.Load<GDScript>("res://scripts/joy_con.gd");
					Node3D joyConNode = (Node3D)myGDScript.New();
					joyConNode.Set("is_right_joycon", false);
					joyConNode.Name = $"JoyCon_Left_{leftJoyCons.Count}";
					AddChild(joyConNode);
					joyConNodes[leftJoyCons.Last()] = joyConNode;
					Godot.GD.Print($"Added left Joy-Con: {joyConNode.Name}");
					// Only add visual for right for now
				}
			}
		}
		else
		{
			Godot.GD.Print("This platform is not supported.");
		}
		
		StartJoyCons();
	}

	public override void _ExitTree()
	{
		base._ExitTree();
		foreach(JoyCon jc in leftJoyCons)
		{
			jc.Stop();
		}
		foreach(JoyCon jc in rightJoyCons)
		{
			jc.Stop();
		}
	}


	private async Task SetInputReport(JoyCon joycon, JoyCon.InputReportType reportType)
	{
		await joycon.SetInputReportModeAsync(reportType);
		return;
	}

	private async Task EnableIMU(JoyCon joycon, bool enable)
	{

		await joycon.EnableImuAsync(enable);
		return;
	}

	private async Task StartConfiguration(JoyCon jc)
	{
		var nodeName = joyConNodes[jc].Name;
		GD.Print("Configuring: ", nodeName);

		readySignals[jc] = new TaskCompletionSource<bool>();

		AttachHandler(jc);

		// ✅ START FIRST (required by library)
		jc.Start();

		await Task.Delay(50); // small buffer so device actually wakes up

		await jc.SetInputReportModeAsync(JoyCon.InputReportType.Full);
		await SetCalibration(jc);
		await jc.EnableImuAsync(true);
		await SetStickParameters(jc);

		// Wait for real IMU data
		var completed = await Task.WhenAny(
			readySignals[jc].Task,
			Task.Delay(2000)
		);

		if (completed != readySignals[jc].Task)
		{
			throw new Exception("JoyCon did not become ready (timeout)");
		}

		GD.Print("READY: ", nodeName);
	}

	private async Task SetCalibration(JoyCon joycon)
	{
		// First try user calibration, if not available, fallback to factory calibration
		calibration[joycon] = await joycon.GetUserCalibrationAsync();
		if (calibration[joycon] == null)
		{   calibration[joycon] = await joycon.GetFactoryCalibrationAsync();
		}
		if (calibration[joycon] == null)
		{
			Godot.GD.Print("No calibration data available.");
			//return;
			calibration[joycon] = new CalibrationData(); // Use default calibration data
		}
		return;
	}

	private async Task SetStickParameters(JoyCon joycon)
	{
		stickParameters[joycon] = await joycon.GetStickParametersAsync();
		return;
	}

	private async Task StartJoyCons()
	{
		foreach (var joycon in rightJoyCons.Concat(leftJoyCons))
		{
			GD.Print("Starting + configuring: ", joyConNodes[joycon].Name);
			
			await RetryAsync(() => StartConfiguration(joycon), 5, 300);
						// ← crucial for Bluetooth stability
		}
		GD.Print("=== ALL 4 JOY-CONS READY ===");
	}

	private async Task RetryAsync(Func<Task> action, int maxAttempts = 5, int delayMs = 200)
	{
		for (int attempt = 1; attempt <= maxAttempts; attempt++)
		{
			try
			{
				await action();
				return; // success → exit
			}
			catch (Exception ex)
			{
				GD.PrintErr($"Attempt {attempt} failed: {ex.Message}");

				if (attempt == maxAttempts)
				{
					GD.PrintErr("All retry attempts failed.");
					throw; // or swallow if you prefer
				}

				await Task.Delay(delayMs);
			}
		}
	}

	const float ACCEL_SCALE = 0.000244f;
	const float GYRO_SCALE  = 0.06103f;

	/*
	working cpp code for reference:
	int16_t accel_raw = read_le16(buf, base + axis*2);
	int16_t gyro_raw  = read_le16(buf, base + 6 + axis*2);

	if (calibration.accel_scale[axis] == 16384) {  // detect default
		frame.samples[sample].accel[axis] =
			static_cast<float>(accel_raw) * 0.000244f;  // ≈ 1/4096 × 4 → ±2 g
	} else {
		// use factory
		frame.samples[sample].accel[axis] =
			static_cast<float>(accel_raw - calibration.accel_offset[axis]) /
			static_cast<float>(calibration.accel_scale[axis]);
	}
	frame.samples[sample].gyro[axis] =
		(gyro_raw - calibration.gyro_offset[axis]) *
		GYRO_SCALE *
		(calibration.gyro_scale[axis] / 13371.0f);
	 */

	private Vector3 GetTranslatedAcceleration(Vector3 rawAcc, CalibrationData calib)
	{
		// Apply calibration to raw acceleration data
		// This is a placeholder implementation; the actual translation would depend on the calibration data structure
		return new Vector3(
			(rawAcc.X - calib.ImuCalibration.AccOriginX) / calib.ImuCalibration.AccSensivityX,
			(rawAcc.Y - calib.ImuCalibration.AccOriginY) / calib.ImuCalibration.AccSensivityY,
			(rawAcc.Z - calib.ImuCalibration.AccOriginZ) / calib.ImuCalibration.AccSensivityZ
		);// * ACCEL_SCALE; // accel scale works when not using calibration data to get close to 1 in units of g
	}
	private Vector3 GetTranslatedGyro(Vector3 rawGyro, CalibrationData calib)
	{
		// Apply calibration to raw gyro data
		// This is a placeholder implementation; the actual translation would depend on the calibration data structure
		return new Vector3(
			(rawGyro.X - calib.ImuCalibration.GyroOriginX) * calib.ImuCalibration.GyroSensivityX,
			(rawGyro.Y - calib.ImuCalibration.GyroOriginY) * calib.ImuCalibration.GyroSensivityY,
			(rawGyro.Z - calib.ImuCalibration.GyroOriginZ) * calib.ImuCalibration.GyroSensivityZ
		) * GYRO_SCALE / 13371.0f; // Scale to get actual angular velocity in degrees per second
	}
}
