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
import map.TileLayer;
import map.MapService;
import com.Button;
import com.ToolBar;
import com.StatusBar;

class Example06 extends Sprite {

    var canvas:Canvas;
    var toolbar:ToolBar;
    var layer:InteractiveLayer;

    static public function main()
    { 
       flash.Lib.current.stage.scaleMode = flash.display.StageScaleMode.NO_SCALE;
       var t:Example06 = new Example06();
       flash.Lib.current.stage.addEventListener(Event.RESIZE, t.stageResized);
       flash.Lib.current.stage.addChildAt(t,0);
    }


    function new()
    {
        super();
   
        toolbar = new ToolBar();
        canvas = new Canvas();
        layer = new InteractiveLayer();

        toolbar.move(0, 0);
        canvas.move(0, 0);
        canvas.setCenter(new LngLat(16.685218,49.482312));
        canvas.addLayer(new TileLayer(new OpenStreetMapService(14), 8));
        canvas.addLayer(layer);

        stageResized(null);
        initToolbar();

        addChild(canvas);
        addChild(toolbar);

        canvas.initialize();

        var me = this;
        canvas.addEventListener(MapEvent.MAP_CLICKED, function(e:MapEvent) { me.layer.addMark(e.point); });
        canvas.addEventListener(MapEvent.MAP_MOUSEMOVE, mouseMove);


    }

    public function stageResized(e:Event)
    {
        toolbar.setSize(flash.Lib.current.stage.stageWidth, 30);
        canvas.setSize(flash.Lib.current.stage.stageWidth, flash.Lib.current.stage.stageHeight);
    }

    function mouseMove(e:map.MapEvent)
    {
       toolbar.setText("longitude:" + LngLat.fmtCoordinate(e.point.lng) + 
                       " latitude:" + LngLat.fmtCoordinate(e.point.lat));
    }

    function initToolbar()
    {
        var me = this;
        toolbar.addButton(new ZoomOutButton(), "Zoom Out", function(b:CustomButton) { me.canvas.zoomOut(); });
        toolbar.addButton(new ZoomInButton(), "Zoom In",  function(b:CustomButton) { me.canvas.zoomIn(); });
    }

}


import map.Layer;
import flash.geom.Point;
import flash.events.MouseEvent;

class InteractiveLayer extends Layer
{
    var marks_lat:Array<Float>;
    var marks_lng:Array<Float>;
    var marks_xy:Array<Point>;
    var marks_fixed:Array<Bool>;
    var marks_count:Int;
    var mark_id:Int;

    public function new()
    { 
        super();
 
        marks_lat = new Array<Float>();
        marks_lng = new Array<Float>();
        marks_fixed = new Array<Bool>();
        marks_xy = new Array<Point>();
        marks_count = 0;

        mouseEnabled = true;
	buttonMode = false;

        addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
        addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove2);

        //test points
        addMark(new LngLat(16.660036,49.487759), true, false);
        addMark(new LngLat(16.663343,49.486342), false, false);
        addMark(new LngLat(16.668463,49.484107), true, false);
        addMark(new LngLat(16.672148,49.483342), false, false);
        addMark(new LngLat(16.678405,49.482557), false, false);
        addMark(new LngLat(16.685218,49.482312), false, false);
        addMark(new LngLat(16.694393,49.477777), true, false);
        addMark(new LngLat(16.710615,49.471790), false, false);

   }
  
   public function addMark(point:LngLat, fixed:Bool = false,  update:Bool = true)
   {
        marks_lng.push(point.lng);
        marks_lat.push(point.lat);
        marks_fixed.push(fixed);
        marks_count = marks_lng.length;

        if (update)
           updateContent(true);
   }

   /* mouse handling methods */
   function hitTest(e:MouseEvent) : Int
   {
        var a:Point = getXY(globalToLocal(new Point(e.stageX, e.stageY)));
        for (i in 0...marks_xy.length)
            if ((Point.distance(marks_xy[i], a) < 8)  && (!marks_fixed[i]))
              return i;
        return -1; 
   }

   function onMouseDown(e:MouseEvent)
   {
        mark_id = hitTest(e);
        if (mark_id != -1) 
        {
           e.stopPropagation();

           removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove2);
           removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
           flash.Lib.current.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
           flash.Lib.current.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
        }
             
   }

   function onMouseUp(e:MouseEvent)
   {
        flash.Lib.current.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
        flash.Lib.current.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
        addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
        addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove2);
   }

   function onMouseMove2(e:MouseEvent)
   {
        buttonMode = false;
        if (hitTest(e) != -1) 
           buttonMode = true;
   }

   function onMouseMove(e:MouseEvent)
   {
        if (mark_id > -1) 
        {
           var p:LngLat = getLngLat(globalToLocal(new Point(e.stageX, e.stageY)));
           marks_lng[mark_id] = p.lng;
           marks_lat[mark_id] = p.lat;
           
           updateContent(true);
        }
   }

   /* drawing methods */
   function drawMark(p:Point, color:Int)
   {
        var s = new flash.display.Shape();
        s.graphics.lineStyle(3,0xFFFFFF);
        s.graphics.beginFill(color);
        s.graphics.drawCircle(20, 20, 7);
        s.graphics.endFill();

        s.filters = [new flash.filters.DropShadowFilter(3,145,0x000000, 0.5)];//, 5, 5, 2, 2, false, false)];

        var bd  = new flash.display.BitmapData(Std.int(s.width + 20),Std.int(s.height + 20), true, 0x00FFFFFF); //w,h
        bd.draw(s);

        graphics.lineStyle(Math.NaN);
        var matrix = new flash.geom.Matrix();
        matrix.translate(p.x- bd.height / 2, p.y - bd.width / 2);
        graphics.beginBitmapFill(bd, matrix, false);
        graphics.drawRect(p.x - bd.height / 2, p.y - bd.width / 2, bd.height, bd.width);
        graphics.endFill();
   }

   override function updateContent(forceUpdate:Bool=false)
   {
        if (!forceUpdate) return;

        graphics.clear();
        marks_xy = new Array<Point>();

        var a:Point = getOriginXY();
        var b:Point = null;
        var zz =  this.mapservice.zoom_def + zoom;
        var ll = this.mapservice.lonlat2XY;

        //draw path
        graphics.lineStyle(6,0x004080, 0.9);
        for (i in 0...marks_count) 
        {
            if (b != null) 
            { 
               b = ll(marks_lng[i], marks_lat[i], zz);
               b = b.subtract(a);
               graphics.lineTo(b.x, b.y);
            } 
            else
            {
               b = ll(marks_lng[i], marks_lat[i], zz);
               b = b.subtract(a);
               graphics.moveTo(b.x, b.y);
            }
        }

        if (zoom < -2) return;

        //draw marks
        for (i in 0...marks_count) 
        {
            b = ll(marks_lng[i], marks_lat[i], zz);
            marks_xy.push(b);
            b = b.subtract(a);
            drawMark(b, (marks_fixed[i]) ? 0xFF0000 : 0x004080);
        }
   }

}
