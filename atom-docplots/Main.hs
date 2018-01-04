module Main where

import ForSyDe.Atom.Utility.Plot
import ForSyDe.Atom.MoC.DE as DE
import ForSyDe.Atom.MoC.CT as CT
import ForSyDe.Atom.MoC.Time as T
import ForSyDe.Atom.MoC.TimeStamp


config = silentCfg { rate=0.1, path="data" }

main :: IO ()
main = do
  putStrLn "Dumping the following files:"
  deDelay    >>= print
  deDelay'   >>= print
  deComb     >>= print
  deReconfig >>= print
  deConstant >>= print
  deGenerate >>= print
  deStated   >>= print
  deState    >>= print
  deMoore    >>= print
  deMealy    >>= print
  deSync     >>= print
  -------------------------
  ctExamp    >>= print
  ctDelay    >>= print
  ctDelay'   >>= print
  ctComb     >>= print
  ctReconfig >>= print
  ctConstant >>= print
  ctInfinite >>= print
  ctGenerate >>= print
  ctGenerate1>>= print
  ctStated   >>= print
  ctState    >>= print
  ctMoore    >>= print
  ctMealy    >>= print
  ctToDE     >>= print
  ctSampDE1  >>= print
  ctSampDE2  >>= print
  ctSubsig   >>= print
  
--------------- DE MoC ---------------

deDelay = dumpLatex $ prepareL cfg [inp, out]
  where
    cfg = config { labels = ["de-delay-i1", "de-delay-o1"] }
    inp = DE.readSignal "{1@0, 2@2, 3@6, 4@8, 5@9}" :: DE.Signal Int
    out = DE.delay 3 0 inp

deDelay' = dumpLatex $ prepareL cfg [in1, in2, out]
  where
    cfg = config {
      labels = ["de-delayp-i1", "de-delayp-i2", "de-delayp-o1"] }
    in1 = DE.readSignal "{1@0, 2@2, 3@6, 4@8, 5@9}" :: DE.Signal Int
    in2 = DE.readSignal "{3@0, 4@4, 5@5, 6@8, 7@9}" :: DE.Signal Int
    out = DE.delay' in1 in2


deComb = dumpLatex $ prepareL cfg [in1, in2, out1, out2]
  where
    cfg = config {
      labels = ["de-comb-i1", "de-comb-i2", "de-comb-o1"
               , "de-comb-o2"] }
    in1 = DE.infinite 1
    in2 = DE.readSignal "{3@0, 4@4, 5@5, 6@8, 7@9}" :: DE.Signal Int
    (out1,out2) = DE.comb22 (\a b-> (a+b,a-b)) in1 in2


deReconfig = dumpLatex $ prepareL cfg [in2, out]
  where
    cfg = config {
      labels = ["de-reconfig-i2", "de-reconfig-o1"] }
    in1 = DE.signal [(0,(+1)),(2,(*2)),(5,(+1)),(7,(*2))] :: DE.Signal (Int->Int)
    in2 = DE.signal [(0,1),(3,2),(5,3),(9,4)] :: DE.Signal (Int)
    out = DE.reconfig11 in1 in2

deConstant = dumpLatex $ prepareL cfg [out]
  where
    cfg = config { labels = ["de-constant-o1"] }
    out = DE.constant1 2 :: DE.Signal Int

deGenerate = dumpLatex $ prepareL cfg [out1, out2]
  where
    cfg = config { labels = ["de-generate-o1", "de-generate-o2"] }
    (out1,out2) = DE.generate2 (\a b -> (a+1,b+2)) ((3,1),(1,2))
      :: (DE.Signal Int, DE.Signal Int) 


-- >>> let s = readSignal "{1@0, 2@2, 3@6, 4@8, 5@9}" :: Signal Int  
-- >>> takeS 7 $ stated11 (+) (6,1) s
-- { 1 @0s, 2 @6s, 3 @8s, 5 @12s, 7 @14s, 8 @15s, 10 @18s}
deStated = dumpLatex $ prepareL cfg [inp, out]
  where
    cfg = config { labels = ["de-stated-i1", "de-stated-o1"] }
    inp = DE.readSignal "{1@0, 2@2, 3@6, 4@8, 5@9}" :: DE.Signal Int
    out = DE.stated11 (+) (6,1) inp

-- >>> let s = readSignal "{1@0, 2@2, 3@6, 4@8, 5@9}" :: Signal Int  
-- >>> takeS 7 $ state11 (+) (6,1) s
-- { 2 @0s, 3 @2s, 5 @6s, 7 @8s, 8 @9s, 10 @12s, 12 @14s}
deState = dumpLatex $ prepareL cfg [inp, out]
  where
    cfg = config { labels = ["de-state-i1", "de-state-o1"] }
    inp = DE.readSignal "{1@0, 2@2, 3@6, 4@8, 5@9}" :: DE.Signal Int
    out = DE.state11 (+) (6,1) inp

-- >>> let s = readSignal "{1@0, 2@2, 3@6, 4@8, 5@9}" :: Signal Int  
-- >>> takeS 7 $ moore11 (+) (+1) (6,1) s
-- { 2 @0s, 3 @6s, 4 @8s, 6 @12s, 8 @14s, 9 @15s, 11 @18s}
deMoore = dumpLatex $ prepareL cfg [inp, out]
  where
    cfg = config { labels = ["de-moore-i1", "de-moore-o1"] }
    inp = DE.readSignal "{1@0, 2@2, 3@6, 4@8, 5@9}" :: DE.Signal Int
    out = DE.moore11 (+) (+1) (6,1) inp

-- >>> let s = readSignal "{1@0, 2@2, 3@6, 4@8, 5@9}" :: Signal Int  
-- >>> takeS 7 $ mealy11 (+) (-) (6,1) s
-- { 0 @0s, -1 @2s, -1 @6s, -1 @8s, -2 @9s, 0 @12s, 2 @14s}
deMealy = dumpLatex $ prepareL cfg [inp, out]
  where
    cfg = config { labels = ["de-mealy-i1", "de-mealy-o1"] }
    inp = DE.readSignal "{1@0, 2@2, 3@6, 4@8, 5@9}" :: DE.Signal Int
    out = DE.mealy11 (+) (-) (6,1) inp

-- >>> let s1 = readSignal "{1@0, 2@2, 3@6, 4@8,  5@9}"  :: Signal Int
-- >>> let s2 = readSignal "{1@0, 2@5, 3@6, 4@10, 5@12}" :: Signal Int
-- >>> sync2 s1 s2
-- ({ 1 @0s, 2 @2s, 2 @5s, 3 @6s, 4 @8s, 5 @9s, 5 @10s, 5 @12s},{ 1 @0s, 1 @2s, 2 @5s, 3 @6s, 3 @8s, 3 @9s, 4 @10s, 5 @12s})
deSync = dumpLatex $ prepareL cfg [in1, in2, out1, out2]
  where
    cfg = config {
      labels = ["de-sync-i1", "de-sync-i2", "de-sync-o1", "de-sync-o2"] }
    in1 = DE.readSignal "{1@0, 2@2, 3@6, 4@8,  5@9}"  :: DE.Signal Int
    in2 = DE.readSignal "{1@0, 2@5, 3@6, 4@10, 5@12}" :: DE.Signal Int
    (out1, out2) = DE.sync2 in1 in2

--------------- CT MoC ---------------

pi' = realToFrac Prelude.pi

ctExamp = dumpLatex $ prepareL cfg [in1, in2, out]
  where
    cfg = config { xmax = 10,
      labels = ["ct-examp-i1", "ct-examp-i2", "ct-examp-o1"] }
    in1 = CT.infinite (T.sin)
    in2 = CT.signal [(0,\_->0), (pi',\_->1), (2*pi',\_->0), (3*pi',\_->1)]
    out = CT.comb21 (+) in1 in2


ctDelay = dumpLatex $ prepareL cfg [inp, out]
  where
    cfg = config { xmax = 10
                 , labels = ["ct-delay-i1", "ct-delay-o1"] }
    inp = CT.infinite (T.sin)
    out = CT.delay 2 (\_ -> 0) inp

ctDelay' = dumpLatex $ prepareL cfg [in2, in1, out]
  where
    cfg = config { xmax = 10,
      labels = ["ct-delayp-i1", "ct-delayp-i2", "ct-delayp-o1"] }
    in1 = CT.infinite (T.sin)
    in2 = CT.signal [(0, \_ -> 0), (2, \_ -> 1)]
    out = CT.delay' in2 in1


ctComb = dumpLatex $ prepareL cfg [in1, in2, out1, out2]
  where
    cfg = config { xmax = 10,
      labels = ["ct-comb-i1", "ct-comb-i2", "ct-comb-o1"
               , "ct-comb-o2"] }
    in1 = CT.infinite (T.sin)
    in2 = CT.signal [(0,\_->0), (pi',\_->1), (2*pi',\_->0), (3*pi',\_->1)]
    (out1,out2) = CT.comb22 (\a b-> (a+b,a*b)) in1 in2


ctReconfig = dumpLatex $ prepareL cfg [in2, out]
  where
    cfg = config { xmax = 10,
      labels = ["ct-reconfig-i2", "ct-reconfig-o1"] }
    in1 = CT.signal [(0,\_->(*0)),(pi',\_->(+1)),(2*pi',\_->(*0)),(3*pi',\_->(+1))]
    in2 = CT.infinite (T.sin)
    out = CT.reconfig11 in1 in2

ctConstant = dumpLatex $ prepareL cfg [out]
  where
    cfg = config { xmax = 10, labels = ["ct-constant-o1"] }
    out = CT.constant1 2 :: CT.Signal Int

ctInfinite = dumpLatex $ prepareL cfg [out1, out2]
  where
    cfg = config { xmax = 10
                 , labels = ["ct-infinite-o1", "ct-infinite-o2"] }
    (out1,out2) = CT.infinite2 (T.sin, T.cos)

ctGenerate = dumpLatex $ prepareL cfg [out]
  where
    cfg = config { xmax = 10, labels = ["ct-generate-o1"] }
    osc 0 = 1
    osc 1 = 0
    out = CT.generate1 osc (pi', \_->0) :: CT.Signal Int

ctGenerate1 = dumpLatex $ prepareL cfg [out]
  where
    cfg  = config { xmax = 3, labels = ["ct-generate1-o1"] }
    vs   = 2                                -- Vs : supply voltage
    r    = 100                              -- R : resistance
    c    = 0.0005                           -- C : capacitance
    vc t = vs * (1 - T.exp (-t / (r * c))) -- Vc(t) : voltage
    ns v = vs + (-1 * v)                  -- next state : 
    out  = CT.generate1 ns (milisec 500, vc)
                                  
ctStated = dumpLatex $ prepareL cfg [inp, out]
  where
    cfg = config { xmax = 10
                 , labels = ["ct-stated-i1", "ct-stated-o1"] }
    osc 0 a = a
    osc _ a = 0
    inp = CT.signal [(0,\_->1), (6,\_->0)] :: CT.Signal Int
    out = CT.stated11 osc (1,\_->0) inp    :: CT.Signal Int

ctState = dumpLatex $ prepareL cfg [inp, out]
  where
    cfg = config { xmax = 10
                 , labels = ["ct-state-i1", "ct-state-o1"] }
    osc 0 a = a
    osc _ a = 0
    inp = CT.signal [(0,\_->1), (6,\_->0)] :: CT.Signal Int
    out = CT.state11 osc (1,\_->0) inp     :: CT.Signal Int

ctMoore = dumpLatex $ prepareL cfg [inp, out]
  where
    cfg = config { xmax = 10
                 , labels = ["ct-moore-i1", "ct-moore-o1"] }
    osc 0 a = a
    osc _ a = 0
    inp = CT.signal [(0,\_->1), (6,\_->0)]   :: CT.Signal Int
    out = CT.moore11 osc (*3) (1,\_->0) inp  :: CT.Signal Int

ctMealy = dumpLatex $ prepareL cfg [inp, out]
  where
    cfg = config { xmax = 10
                 , labels = ["ct-mealy-i1", "ct-mealy-o1"] }
    osc (-1) _ = 1
    osc 1 _ = (-1)
    inp = CT.infinite T.sin
    out = CT.mealy11 osc (*) (pi',\_->1) inp


ctToDE = dumpLatex $ prepareL cfg [inp]
  where
    cfg = config { xmax = 9
                 , labels = ["ct-tode-i1"] }
    inp = CT.signal [(0, T.sin), (3,T.cos), (6,T.sin)]

-- >>> let s = CT.infinite (fromRational . sin')
-- >>> let c = DE.generate1 id (pi'/2, 1)
-- >>> takeS 6 $ sampDE1 c s
ctSampDE1 = dumpLatex $ prepareL cfg [inp1]
  where
    cfg = config { xmax = 8
                 , labels = ["ct-sampde-i1"] }
    inp1 = CT.infinite (T.sin) :: CT.Signal Time
    
ctSampDE2 = dumpLatex $ prepareL cfg [inp2,out1]
  where
    cfg = config { xmax = 8
                 , labels = ["ct-sampde-i2", "ct-sampde-o1"] }
    pi'  = realToFrac Prelude.pi
    inp1 = CT.infinite (fromRational . T.sin) :: CT.Signal Double
    inp2 = DE.generate1 id (pi'/2, 1)
    out1 = CT.sampDE1 inp2 inp1

ctSubsig = dumpLatex $ prepareL cfg [sig1,sig2,sig3]
  where
    cfg = config { xmax = 6
                 , labels = [ "ct-subsig-s1", "ct-subsig-s2"
                            , "ct-subsig-s3"] }
    sig1 = CT.infinite (T.sin)
    sig2 = CT.infinite (T.cos)
    sig3 = CT.signal [(0, T.sin), (3,T.cos)]
  
