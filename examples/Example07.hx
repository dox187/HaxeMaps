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

class Example07p extends Sprite {

    var canvas:Canvas;
    var toolbar:ToolBar;

    static public function main()
    { 
       flash.Lib.current.stage.scaleMode = flash.display.StageScaleMode.NO_SCALE;
       var t:Example07p = new Example07p();
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
        canvas.setCenter(new LngLat(16.6, 49.2));
        canvas.addLayer(new map.TileLayer(new OpenStreetMapService(), 8));
        canvas.addLayer(new VectorLayer(refresh));
        canvas.setZoom(-2);
        stageResized(null);

        initToolbar();

        addChild(canvas);
        addChild(toolbar);

        canvas.initialize();
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
    }

    function refresh(lng:Float, lat:Float, dist:Float)
    {
        canvas.panTo(new LngLat(lng, lat));
        toolbar.setText("Total dist.: "+dist+" km");
    }
}

import flash.net.URLLoader;
import flash.net.URLRequest;
import flash.utils.ByteArray;
import flash.geom.Point;
import flash.utils.Timer;
import flash.events.TimerEvent;
import map.Layer;

typedef Refresh = Float -> Float -> Float -> Void;

class VectorLayer extends Layer
{
    static var URL:String = "http://localhost/path.bin";

    var plon:Array<Float>;
    var plat:Array<Float>;
    var maxlen:Int;
    var timer:Timer;
    var refresh:Refresh;

    public function new(refresh: Refresh)
    { 
        super();

        this.refresh = refresh;
        this.timer = new Timer(50, 0);
        this.plon = new Array<Float>();
        this.plat = new Array<Float>();

        var urlLoader:URLLoader = new URLLoader();
        urlLoader.dataFormat = flash.net.URLLoaderDataFormat.BINARY;
        urlLoader.addEventListener(Event.COMPLETE, processData);
        urlLoader.addEventListener(flash.events.IOErrorEvent.IO_ERROR, 
                                    function(e) { trace("Can't load data");}
                                   );
        try {
            var urlRequest:URLRequest = new URLRequest(URL);
            urlLoader.load(urlRequest);
        } catch (unknown : Dynamic)  {
            trace("Error - Unable to load data");
        }

        maxlen = 0;
    }

    function processData(e:Event)
    {
        var loader:URLLoader = e.target;
        loader.removeEventListener(Event.COMPLETE, processData);

        var b:ByteArray = loader.data;
        try 
        {
           b.uncompress();

           var len:Int =  b.readUnsignedShort();
           for (i in 0...len)
           {
               plon.push(b.readDouble());
               plat.push(b.readDouble());
           }

           timer.addEventListener(TimerEvent.TIMER, animate);
           timer.start();

           updateContent(true);

        } 
        catch (unknown : Dynamic)  
        {
            trace("Error - Unable to read data");
        }
    }

    function animate(e:TimerEvent)
    {
        if (maxlen < plon.length) 
        {
           maxlen++;
           if (maxlen % 20 == 0)
           {

              //calc total distance
              var dist:Float = 0;
              for (i in 1...maxlen)
                 dist += LngLat.distance(new LngLat(plon[i],plat[i]), new LngLat(plon[i-1],plat[i-1]));
              dist = Std.int(dist / 100.0) / 10.0;

              //pan canvas to the last point, update info
              refresh(plon[maxlen-1], plat[maxlen-1], dist);
           }

           //redraw content
           updateContent(true);
        }
        else 
        {
           timer.stop();
           timer.removeEventListener(TimerEvent.TIMER_COMPLETE, animate);
        }
    }

    override function updateContent(forceUpdate:Bool=false)
    {
        if (!forceUpdate) return;

        var z:Int = this.mapservice.zoom_def + this.zoom;
        var l2pt = this.mapservice.lonlat2XY;
        var cpt:Point = l2pt(center.lng, center.lat, z);
        var pt:Point;

        //draw the path
        graphics.clear();
        graphics.lineStyle(4,0xFF0000);
        for (i in 0...maxlen)
        { 
            pt = l2pt(plon[i], plat[i], z);
            if (i == 0) 
               graphics.moveTo((pt.x - cpt.x), (pt.y - cpt.y));
            else
               graphics.lineTo((pt.x - cpt.x), (pt.y - cpt.y));
        }

    }
}
