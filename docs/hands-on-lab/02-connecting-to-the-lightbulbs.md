# Connecting to the Lightbulbs

While there are no technical restrictions on the kinds of remote devices or APIs you can connect to with transports, for the purpose of this workshop we are connecting to a Philips HUE hub and make some colourful wireless lightbulbs light up. If you (understandably) do not have physical devices available, you can get going with the Hue Emulator.

## Hue Emulator

Download the [HueEmulator-v0.8.jar](https://github.com/SteveyO/Hue-Emulator/blob/master/HueEmulator-v0.8.jar) from [SteveyO/Hue-Emulator](https://github.com/SteveyO/Hue-Emulator).

To run this emulator, you will need to have a Java Runtime installed. Once you have java installed, use `java -jar` with the emulator's filename to run it:

```
david@davids:~$ java -jar ~/Downloads/HueEmulator-v0.8.jar
```

It will not produce any output on the command line, but it will pop up a window with a hub and a few predefined lights:

![](./02-connecting-to-the-lightbulbs-emulator.png)

All you need now is to input a port (the default 8000 is usually fine) and press "Start" to activate the built-in server.

## Connecting to your hub

To connect to an actual hub, you will need be able to access the Hub on your network and get an API key. Follow the [Philips Developer docs](http://www.developers.meethue.com/documentation/getting-started) (registration required) for that.


## Next up

Once you have some lights up, head on to [create a new module](./03-creating-a-new-module.md).
