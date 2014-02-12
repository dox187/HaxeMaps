Original source: [https://code.google.com/p/haxemaps/](https://code.google.com/p/haxemaps/ "Original source")

HaxeMaps
========

![HaxeMaps](http://www.fit.vutbr.cz/~vasicek/docs_imgs/map_index/haxemaps.png "HaxeMaps")

Haxemaps is an library written in Haxe language designed to accelerate the implementation of a map application. The proposed framework allows to arbitrary combine vector and raster (e.g. tile-layer, WMS image) layers or overlays. On top of that it is possible to easily extend the basic functionality and implement custom static as well as interactive layers.

The documentation (in Czech) as well as the online demo can be found [here]. 

[here]: http://www.fit.vutbr.cz/~vasicek/docs/map_index.htm


## Setup/Installing:

dependency: http://openfl.org/

```
haxelib git haxemap https://github.com/dox187/HaxeMaps.git
```

## How to use:

Include Haxemap library: 
**project.xml**
```xml
<haxelib name="haxemap" />
```

**Main.hx**
```haxe
import flash.display.Sprite;
import haxemap.OnlineMap;

class Main extends Sprite {
	public function new () {
		super ();
		var map = new OnlineMap();
			map.init(stage.stageWidth,stage.stageHeight);
		addChild(map);
		
	}
}
```

