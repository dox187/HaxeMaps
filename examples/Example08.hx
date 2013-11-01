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

class Example08 extends Sprite {

    var canvas:Canvas;
    var toolbar:ToolBar;
    var layer_osm:map.TileLayer;

    static public function main()
    { 
       flash.Lib.current.stage.scaleMode = flash.display.StageScaleMode.NO_SCALE;
       var t:Example08 = new Example08();
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
        layer_osm = new map.TileLayer(new OpenStreetMapService(12), 8);
        canvas.addLayer(layer_osm);
        canvas.addLayer(new VectorLayer(new OpenStreetMapService(12)));
        canvas.setZoom(-5);
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
        toolbar.addSeparator(30);

        //pan buttons
        toolbar.addButton(new UpButton(), "Move up",  function(b:CustomButton) { me.pan(1); });
        toolbar.addButton(new DownButton(), "Move down",  function(b:CustomButton) { me.pan(2); });
        toolbar.addButton(new LeftButton(), "Move left",  function(b:CustomButton) { me.pan(4); });
        toolbar.addButton(new RightButton(), "Move right",  function(b:CustomButton) { me.pan(8); });

        //layer buttons
        toolbar.addSeparator(50);
        var me = this;
        var tbosm = new TextButton("OSM Layer");
        tbosm.checked = true;
        toolbar.addButton(tbosm, "Open Street Map Layer",  
                          function(b:CustomButton) 
                          { 
                            tbosm.checked = !tbosm.checked;
                            if (tbosm.checked)
                               me.canvas.enableLayer(me.layer_osm); 
                            else 
                               me.canvas.disableLayer(me.layer_osm); 
                          });

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

}

import flash.net.URLLoader;
import flash.net.URLRequest;
import flash.utils.ByteArray;
import flash.geom.Point;
import map.Layer;
import map.QuadTree;

import flash.utils.Timer;
import flash.events.TimerEvent;

class VectorLayer extends Layer
{
    var data:QuadTree;
    var ftimer:Timer;

    public static var COLORS = [0xB2182B, 0xD6604D, 0xF4A582, 0xFDDBC7, 0xE0E0E0, 0xBABABA, 0x878787, 0x4D4D4D];

    public function new(map_service:MapService = null)
    { 
        super(map_service, false);


        ftimer = new Timer(100, 1);
        ftimer.addEventListener(TimerEvent.TIMER_COMPLETE, redraw);

        data = new QuadTree();
        for (i in 0...100000)
        {
            var lng:Float = -30 + Math.random()*100;
            var lat:Float = Math.random()*80; 
            var clr:Int = Math.floor(Math.random()*8);
            var r:Int = 5 + (1 << Math.floor(i / 10000));
            data.push(lng,lat, {color: COLORS[clr], radius: r});
        }
    }

    override function updateContent(forceUpdate:Bool=false)
    {
        if (ftimer.running)
           ftimer.stop();

        if (forceUpdate)
           redraw(null);
        else
           ftimer.start();
    }

    function redraw(e:TimerEvent)
    {

        var zz:Int = this.mapservice.zoom_def + this.zoom;
        var scale:Float = Math.pow(2.0, this.zoom);
        var l2pt = this.mapservice.lonlat2XY;
        var cpt:Point = l2pt(center.lng, center.lat, zz);
        var pt:Point;

        graphics.clear();
        var lt:LngLat = getLeftTopCorner();
        var rb:LngLat = getRightBottomCorner();

 	//var data:Array<QuadData> = data.getData(lt.lng, rb.lat, rb.lng, lt.lat);

        var minsz:Float = 1.0/scale;
        var data:Array<QuadData> = data.getFilteredData(lt.lng, rb.lat, rb.lng, lt.lat, function(q:QuadData):Bool { return q.data.radius > minsz;}); //return scale*q.data.radius > 0.8;});

        var r:Float;
        for (d in data)
        {
            r = scale*d.data.radius;
            pt = l2pt(d.x, d.y, zz);
            graphics.lineStyle(r/2.0, d.data.color);
            graphics.drawRect((pt.x - cpt.x), (pt.y - cpt.y), r, r);
        }
    }
}
