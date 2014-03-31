import Graphics.Input as Input

----  Put it all on screen  ----

style : Input.Input Style
style = Input.input Line

points : Input.Input [(Float,Float)]
points = Input.input (snd (head pointOptions))

main : Signal Element
main = lift2 scene style.signal points.signal

scene : Style -> [(Float,Float)] -> Element
scene currentStyle currentPoints =
  flow down
    [ plot currentStyle 400 400 currentPoints
    , flow right [ plainText "Options: "
                 , Input.dropDown points.handle pointOptions
                 , Input.dropDown style.handle styleOptions
                 ]
    ]


----  Graph Styles  ----

data Style = Points | Line

styleOptions : [(String,Style)]
styleOptions = [ ("Line Graph", Line), ("Scatter Plot", Points) ]


----  Many graphs for display  ----

lissajous : Float -> Float -> Float -> (Float,Float)
lissajous m n t = (cos (m*t), sin (n*t))

pointOptions : [( String, [(Float,Float)] )]
pointOptions =
    [ ("r = cos(4t)", polarGraph (\t -> cos (4*t)) piRange)
    , ("Lissajous"  , map (lissajous 3 2) piRange)
    , ("Circle"     , map (\t -> (cos t, sin t)) piRange)
    , ("x^2"        , graph (\x -> x*x) range)
    , ("x^2 + x - 9", graph (\x -> x*x + x - 9) offRange)
    , ("x^3"        , graph (\x -> x*x*x) range)
    , ("Sin Wave"   , graph sin piRange)
    , ("Cosine Wave", graph cos piRange)
    , ("Scattered"  , graph (\x -> x + tan x) range)
    ]

range : [Float]
range = map toFloat [ -10 .. 10 ]

piRange : [Float]
piRange = map (\x -> toFloat x / 40 * pi) [-40..40]

offRange : [Float]
offRange = map (\x -> toFloat x / 5) [-20..10]

graph : (Float -> Float) -> [Float] -> [(Float,Float)]
graph f range = zip range (map f range)

polarGraph : (Float -> Float) -> [Float] -> [(Float,Float)]
polarGraph f thetas =
    zipWith (\r t -> fromPolar (r,t)) (map f thetas) thetas


----  Render graphs from scratch  ----

plot : Style -> Float -> Float -> [(Float,Float)] -> Element
plot style w h points =
  let (xs,ys) = unzip points
      eps = 26/25
      (xmin, xmax) = (eps * minimum xs, eps * maximum xs)
      (ymin, ymax) = (eps * minimum ys, eps * maximum ys)
      fit scale lo hi z = scale * abs (z-lo) / abs (hi-lo)
      f (x,y) = (fit w xmin xmax x, fit h ymin ymax y)
      axis a b = traced (solid black) . path . map f <| [a,b]
      xaxis = axis (xmin, clamp ymin ymax 0) (xmax, clamp ymin ymax 0)
      yaxis = axis (clamp xmin xmax 0, ymin) (clamp xmin xmax 0, ymax)
      draw ps = case style of
                  Points -> map (\p -> move p . outlined (solid lightBlue) <| ngon 4 3) ps
                  Line   -> [ traced (solid lightBlue) <| path ps ]
  in  collage (round w) (round h) [ move (-200,-200) . group <| [ xaxis, yaxis ] ++ draw (map f points) ]