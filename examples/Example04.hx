/*******************************************************************************
Copyright (c) 2010, Zdenek Vasicek (vasicek AT fit.vutbr.cz)
                    Marek Vavrusa  (marek AT vavrusa.com)
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the organization nor the names of its
      contributors may be used to endorse or promote products derived from this
      software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE. 
*******************************************************************************/

import flash.display.Sprite;
import flash.events.Event;
import map.Canvas;
import map.LngLat;
import map.MapService;
import com.Button;
import com.ToolBar;

class Example04 extends Sprite {

    var canvas:Canvas;
    var toolbar:ToolBar;

    static public function main()
    { 
       flash.Lib.current.stage.scaleMode = flash.display.StageScaleMode.NO_SCALE;
       var t:Example04 = new Example04();
       flash.Lib.current.stage.addEventListener(Event.RESIZE, t.stageResized);
       flash.Lib.current.stage.addChildAt(t,0);
    }


    function new()
    {
        super();
   
        toolbar = new ToolBar();
        canvas = new Canvas();

        toolbar.move(0, 0);
        canvas.move(0, 0);
        canvas.setCenter(new LngLat(15.5,49.5));
        #if TILE_LAYER
        canvas.addLayer(new map.TileLayer(new OpenStreetMapService(12), 8));
        #end
        canvas.addLayer(new VectorLayer(new OpenStreetMapService(12)));
        canvas.setZoom(-4);
        stageResized(null);

        initToolbar();

        addChild(canvas);
        addChild(toolbar);

        canvas.initialize();
        canvas.addEventListener(MapEvent.MAP_MOUSEMOVE, mouseMove);

    }

    public function stageResized(e:Event)
    {
        toolbar.setSize(flash.Lib.current.stage.stageWidth, 30);
        canvas.setSize(flash.Lib.current.stage.stageWidth, flash.Lib.current.stage.stageHeight);
    }

    function initToolbar()
    {
        var me = this;
        toolbar.addButton(new ZoomOutButton(), "Zoom Out", function(b:CustomButton) { me.canvas.zoomOut(); });
        toolbar.addButton(new ZoomInButton(), "Zoom In",  function(b:CustomButton) { me.canvas.zoomIn(); });
        toolbar.addSeparator(30);
        //pan buttons
        toolbar.addButton(new UpButton(), "Move up",  function(b:CustomButton) { me.pan(1); });
        toolbar.addButton(new DownButton(), "Move down",  function(b:CustomButton) { me.pan(2); });
        toolbar.addButton(new LeftButton(), "Move left",  function(b:CustomButton) { me.pan(4); });
        toolbar.addButton(new RightButton(), "Move right",  function(b:CustomButton) { me.pan(8); });
    }

    function pan(direction:Int)
    {
       var lt:LngLat = canvas.getLeftTopCorner();
       var br:LngLat = canvas.getRightBottomCorner();
       var p:LngLat  = canvas.getCenter();

       if (direction & 0x3 == 1) p.lat = lt.lat; //up
       if (direction & 0x3 == 2) p.lat = br.lat; //down
       if (direction & 0xC == 4) p.lng = lt.lng; //left
       if (direction & 0xC == 8) p.lng = br.lng; //right

       canvas.panTo(p);
    }

    function mouseMove(e:map.MapEvent)
    {
       toolbar.setText("longitude:" + LngLat.fmtCoordinate(e.point.lng) + 
                       " latitude:" + LngLat.fmtCoordinate(e.point.lat) + 
                       " zoom:" + canvas.getZoom());
    }

}

import flash.net.URLLoader;
import flash.net.URLRequest;
import flash.utils.ByteArray;
import flash.geom.Point;
import map.Layer;

class VectorLayer extends Layer
{
    static var URL:String = "http://www.fit.vutbr.cz/~vasicek/map_proxy.php?service=k&id=";

    var plon:Array<Float>;
    var plat:Array<Float>;
    var colors:Array<Int>;

    public function new(map_service:MapService = null)
    { 
        super(map_service, true);

        plon = new Array<Float>();
        plat = new Array<Float>();
        colors = [0xB2182B, 0xD6604D, 0xF4A582, 0xFDDBC7, 0xE0E0E0, 
                  0xBABABA, 0x878787, 0x4D4D4D, 0xD9EF8B, 0xA6D96A, 
                  0x66BD63, 0x1A9850, 0x92C5DE, 0x4393C3];

        for (i in 0...14)
        {
            var urlLoader:URLLoader = new URLLoader();
            urlLoader.dataFormat = flash.net.URLLoaderDataFormat.BINARY;
            urlLoader.addEventListener(Event.COMPLETE, processData);
            urlLoader.addEventListener(flash.events.IOErrorEvent.IO_ERROR, 
                                       function(e) { trace("Can't load data");}
                                      );

            try {
                var urlRequest:URLRequest = new URLRequest(URL+(14-i));
                urlLoader.load(urlRequest);
            } catch (unknown : Dynamic)  {
                trace("Error - Unable to load data");
            }
        }

    }

    function processData(e:Event)
    {
        var loader:URLLoader = e.target;
        loader.removeEventListener(Event.COMPLETE, processData);

        var b:ByteArray = loader.data;
        try 
        {
           b.uncompress();

	   var s:String = b.readUTF();
           //trace(s);

           if (plat.length > 0)  
           { 
             plat.push(0); //sentinel
             plon.push(0); //sentinel
           }

           var len:Int =  b.readUnsignedShort();
           for (i in 0...len)
           {
               plat.push(b.readDouble());
               plon.push(b.readDouble());
           }

           updateContent(true);

        } 
        catch (unknown : Dynamic)  
        {
            trace("Error - Unable to read data");
        }
    }

    override function updateContent(forceUpdate:Bool=false)
    {
        if (!forceUpdate) return;

        var z:Int = this.mapservice.zoom_def;
        var l2pt = this.mapservice.lonlat2XY;
        var cpt:Point = l2pt(center.lng, center.lat, z);
        var pt:Point;
        var calpha = #if TILE_LAYER 0.5 #else 0.9 #end;

        graphics.clear();
        graphics.lineStyle(1,0xF00040);
        graphics.beginFill(0xF00000, calpha);

        var first:Bool = true;
        var id:Int = 0;

        for (i in 0...plon.length)
        {
            if ((plon[i] == 0) && (plat[i] == 0)) 
            {
               graphics.endFill();
               first = true;
               graphics.beginFill(colors[id], calpha);
               id++;
               continue;
            }

            pt = l2pt(plon[i],plat[i], z);
            if (!first) 
            {
               graphics.lineTo((pt.x - cpt.x), (pt.y - cpt.y));
            } 
            else 
            {
               graphics.moveTo((pt.x - cpt.x), (pt.y - cpt.y));
               first = false;
            }
        }

        graphics.endFill();
    }
}
