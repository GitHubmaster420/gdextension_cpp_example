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

	private async Task StartConfiguration(JoyCon joycon)
	{
		var nodeName = joyConNodes[joycon].Name;

		GD.Print("starting configuration for: ", nodeName);

		// ==================== ADD THIS BLOCK FIRST ====================
		var jc = joycon;

		jc.ReportReceived += (s, input) =>
		{
			if (input is InputFullWithImu fullReport)
			{
				if (!calibration.ContainsKey(jc) || calibration[jc] == null ||
					!joyConNodes.ContainsKey(jc) || joyConNodes[jc] == null)
				{
					GD.Print("Early report skipped for ", joyConNodes.TryGetValue(jc, out var n) ? n.Name : jc.ToString());
					return Task.CompletedTask;
				}
				var calib = calibration[jc];
				if (calib?.ImuCalibration == null)
				{
					GD.Print("no imu calibration");
					return Task.CompletedTask;
				}
				joyConRawAccData[jc] = new Vector3();
				joyConRawGyroData[jc] = new Vector3();
				var imu = fullReport.Imu;
				var buttons = fullReport.Buttons;
				Dictionary<string, bool> buttonStates = new Dictionary<string, bool>()
				{
					{"a", buttons.A},
					{"right", buttons.Right},
					{"b", buttons.B},
					{"down", buttons.Down},
					{"x", buttons.X},
					{"up", buttons.Up},
					{"y", buttons.Y},
					{"left", buttons.Left},
					{"l", buttons.L},
					{"r", buttons.R},
					{"zl", buttons.ZL},
					{"zr", buttons.ZR},
					{"plus", buttons.Plus},
					{"minus", buttons.Minus},
					{"left_stick", buttons.Left},
					{"right_stick", buttons.Right},
					{"home", buttons.Home},
					{"capture", buttons.Capture}
				};
				Godot.Collections.Dictionary gdButtonStates = new Godot.Collections.Dictionary();
				foreach (var kvp in buttonStates)				{
					gdButtonStates[kvp.Key] = kvp.Value;
				}
				joyConNodes[jc].CallDeferred("set_meta", "buttons", gdButtonStates);	
				IStickPosition leftStickSimple = fullReport.LeftStick;
				IStickPosition rightStickSimple = fullReport.RightStick;
				IStickPosition stickPos = leftJoyCons.Contains(jc) ? leftStickSimple : rightStickSimple;
				StickPositionCalibrated? stickCalibrated = null;
				if (leftJoyCons.Contains(jc))
				{
					if (calibration[jc].LeftStickCalibration != null)
						stickCalibrated = fullReport.LeftStick.GetCalibrated(calibration[jc].LeftStickCalibration!, stickParameters[jc].LeftStickParameters.DeadZone);
					}
				else
				{
					if(calibration[jc].RightStickCalibration != null)
						stickCalibrated = fullReport.RightStick.GetCalibrated(calibration[jc].RightStickCalibration!, stickParameters[jc].RightStickParameters.DeadZone);
					}
				const float CENTER = 2048.0f;
				const float RANGE = 2048.0f;
				float x = (stickPos.X - CENTER) / RANGE * 2f;
				float y = (stickPos.Y - CENTER) / RANGE * 2f;
				if (stickCalibrated != null)
				{
					StickPositionCalibrated notNull = stickCalibrated.Value;
					x = (float)notNull.X;
					y = (float)notNull.Y;
				}
				
				//StickPositionCalibrated leftStickCalibrated 
				//StickPositionCalibrated rightStickCalibrated
				Dictionary<string, Vector2> stickPositions = new Dictionary<string, Vector2>()
				{
					{"stick", new Vector2(x, y)}
				};
				Godot.Collections.Dictionary stickPositionsGD = new Godot.Collections.Dictionary();
				foreach (var kvp in stickPositions)
				{stickPositionsGD[kvp.Key] = kvp.Value;
				}
				
				joyConNodes[jc].CallDeferred("set_meta", "stick", stickPositionsGD);
				var acc = Vector3.Zero;
				var gyro = Vector3.Zero;
				for(int i = 0; i < imu.Frames.Count; i++)
				{
					joyConRawAccData[jc] += (new Vector3(imu.Frames[i].AccelX, imu.Frames[i].AccelY, imu.Frames[i].AccelZ));
					joyConRawGyroData[jc] += (new Vector3(imu.Frames[i].GyroX, imu.Frames[i].GyroY, imu.Frames[i].GyroZ));
					var frameCalibrated = imu.Frames[i].GetCalibrated(calibration[jc].ImuCalibration);
					acc += new Vector3((float)frameCalibrated.AccelX, (float)frameCalibrated.AccelY, (float)frameCalibrated.AccelZ);
					gyro += new Vector3((float)frameCalibrated.GyroX, (float)frameCalibrated.GyroY, (float)frameCalibrated.GyroZ);
				}
				joyConRawAccData[jc] /= imu.Frames.Count;
				joyConRawGyroData[jc] /= imu.Frames.Count;
				acc /= imu.Frames.Count;
				gyro /= imu.Frames.Count;
				joyConTranslatedAccData[jc] = GetTranslatedAcceleration(joyConRawAccData[jc], calibration[jc]);
				joyConTranslatedGyroData[jc] = GetTranslatedGyro(joyConRawGyroData[jc], calibration[jc]);
				joyConNodes[jc].CallDeferred("set_meta", "acc", acc);
				joyConNodes[jc].CallDeferred("set_meta", "gyro_s", gyro);
				// Integrate gyro data to get total rotation
				
			}
			return Task.CompletedTask;
		};
		GD.Print($"For {nodeName}: calibration.ContainsKey(joycon) = {calibration.ContainsKey(jc)}");
		jc.Start();
		GD.Print($"joyConNodes ContainsKey(joycon) = {joyConNodes.ContainsKey(jc)}");
		jc.StoppedOnError += (s, ex) =>
		{
			GD.PrintErr("!!! ERROR on ", nodeName, " → ", ex.Message);
			if (ex.InnerException != null)
				GD.PrintErr("Inner: ", ex.InnerException.Message);
			GD.PrintErr("Stack: ", ex.StackTrace);
			return Task.CompletedTask;
};
		// ============================================================
		
		GD.Print($"For {nodeName}: calibration.ContainsKey(joycon) = {calibration.ContainsKey(joycon)}");
		GD.Print($"joyConNodes.ContainsKey(joycon) = {joyConNodes.ContainsKey(joycon)}");
		await joycon.SetInputReportModeAsync(JoyCon.InputReportType.Full);
		await Task.Delay(80);

		GD.Print("setting calibration for: ", nodeName);
		await SetCalibration(joycon);
		await Task.Delay(50);
		GD.Print("Calibration loaded for ", nodeName, " - success: ", calibration.ContainsKey(joycon) && calibration[joycon] != null);

		GD.Print("setting imu");
		// your calibration print (optional)

		await joycon.EnableImuAsync(true);
		await Task.Delay(80);
		GD.Print("imu enabled for ", nodeName);
		GD.Print("setting stick parameter");
		await SetStickParameters(joycon);
		GD.Print("code runs for ", nodeName);
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
			
			await StartConfiguration(joycon);   // now fully sequential
			await Task.Delay(350);  
						// ← crucial for Bluetooth stability
		}
		GD.Print("=== ALL 4 JOY-CONS READY ===");
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
