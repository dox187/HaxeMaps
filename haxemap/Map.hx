package haxemap;
import flash.display.Bitmap;
import flash.events.MouseEvent;
import flash.geom.Point;
import haxemap.core.Layer;
import nme.Assets;
import nme.display.BitmapData;
import nme.display.Sprite;
import haxemap.core.Canvas;
import haxemap.core.LngLat;
import haxemap.core.TileLayer;
import haxemap.core.MapService;
import haxemap.ui.Button;
import haxemap.ui.ToolBar;
import haxemap.ui.StatusBar;
import nme.events.Event;


class Map extends Sprite
{
	public var canvas:Canvas;
    public var toolbar:ToolBar;
    public var markers:MarkerLayer;

	public function new()  
	{
		super();
	}
	
	public function init(?w:Float=550,h:Float=400)
	{
		canvas = new Canvas();
        markers = new MarkerLayer();
		
		canvas.move(0, 0);
        canvas.setSize(w, h);
		canvas.setCenter(new LngLat(144.6, -38));
        canvas.addLayer(new TileLayer(new OpenStreetMapService(9), 8));
        canvas.addLayer(markers);
		
        addChild(canvas);
        
        canvas.initialize();
	}
}

class MarkerLayer extends Layer
{
	public var markers:Array<Marker>;
	
	public function new()
	{
		super();
		
		markers = [];
	}
	
	public function addMarker(marker:Marker):Marker
	{
		markers.push(marker);
		return marker;
	}
	
	override public function updateContent(forceUpdate:Bool=false)
	{
		if (!forceUpdate) return;
		
		var c=0;
		for (m in markers)
		{
			c++;
			var xy = mapservice.lonlat2XY(m.lngLat.lng, m.lngLat.lat, mapservice.zoom_def + zoom);
			xy = xy.subtract(getOriginXY());
		
			// TODO : do a bounds check or QuadTree to remove markers which are offscreen. 
			m.x = xy.x;
			m.y = xy.y;
			addChild(m);
		}
	}
}

class Marker extends Sprite
{
	public var lngLat:LngLat;
	public var bitmap:Bitmap;
	
	public function new(bitmapData:BitmapData, center:Point, lngLat:LngLat, ?resolution:Float=2)
	{
		super();
		
		this.lngLat = lngLat;
		
		bitmap = new Bitmap(bitmapData);
		bitmap.scaleX = bitmap.scaleY = 1 / resolution;
		bitmap.x = -center.x/resolution;
		bitmap.y = -center.y/resolution;
		addChild(bitmap);
	}
}