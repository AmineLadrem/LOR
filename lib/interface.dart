import 'package:flutter/material.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

const ballSize = 20.0;
const step = 10.0;
const motorMaxValue = 1023.0; // Adjust this based on your motor driver

class Controller extends StatefulWidget {
  const Controller({Key? key}) : super(key: key);

  @override
  State<Controller> createState() => _ControllerState();
}

class _ControllerState extends State<Controller> {
  double _x1 = 0;
  double _y1 = 0;
  double _x2 = 0;
  double _y2 = 0;
  MqttServerClient? mqttClient;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple[100],
       
      body:  Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
        
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Joystick(
                      listener: (details) {
                        setState(() {
                          _x1 = details.y;
                          _y1 = details.x;
                          print('Joystick 1 - X: $_x1, Y: $_y1');

                          double motor1Value = _y1 * motorMaxValue;
                          double motor2Value = _y1 * motorMaxValue - _x1 * motorMaxValue;

                          // Use motor values to control your motors 1 and 2
                          // Send these values to your motor driver for motors 1 and 2
                          print('Motor 1 Value: $motor1Value');
                          print('Motor 2 Value: $motor2Value');
                          _publishJoystickValues(motor1Value, motor2Value, '12');
                        });
                      },
                    ),
                    Joystick(
                      listener: (details) {
                        setState(() {
                          _x2 = details.y; // Negate the x value to switch direction
                          _y2 = details.x; // Negate the y value to switch direction
                          print('Joystick 2 - X: $_x2, Y: $_y2');

                          double motor3Value = _y2 * motorMaxValue;
                          double motor4Value = _y2 * motorMaxValue - _x2 * motorMaxValue;

                          // Use motor values to control your motors 3 and 4
                          // Send these values to your motor driver for motors 3 and 4
                          print('Motor 3 Value: $motor3Value');
                          print('Motor 4 Value: $motor4Value');
                           _publishJoystickValues(motor3Value, motor4Value, '34');
                        });
                      },
                    ),
  
                  ],
                ),
                Transform.rotate(
                          angle: 1.57,
                          child: ElevatedButton(
                                            onPressed: () {
                                              _connectToMqttBroker();
                                            },
                                            child: Text('Establish Connection'),
                                          ),
                        ),
              ],
            ),

    );
  }

  void _connectToMqttBroker() async {
    mqttClient = MqttServerClient('192.168.1.7', 'lor');
    mqttClient?.port = 1883; // Change to your broker's port if different
    mqttClient?.logging(on: true);

    final connMessage = MqttConnectMessage()
        .withClientIdentifier('lor')
        .startClean()
        .withWillTopic('12')
        .withWillMessage('34')
        .withWillQos(MqttQos.atLeastOnce);

    mqttClient?.connectionMessage = connMessage;

    try {
      await mqttClient?.connect();
      print('Connected to the broker');
    } catch (e) {
      print('Failed to connect: $e');
    }
  }

    void _publishJoystickValues(double x, double y, String topic) {
    final message = MqttClientPayloadBuilder();
    message.addString('$x,$y'); // Assuming you want to send x and y values as a string

    mqttClient?.publishMessage(topic, MqttQos.atLeastOnce, message.payload!);
  }

  @override
  void dispose() {
    mqttClient?.disconnect();
    super.dispose();
  }
}
