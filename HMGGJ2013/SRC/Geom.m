//
//  Geom.c
//  HMGGJ2013
//
//  Created by Jan Ilavsky on 2/2/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

float lineSegmentPointDistance2(CGPoint v, CGPoint w, CGPoint p) {
    
    // Return minimum distance between line segment vw and point p
    const float l2 = ccpDistanceSQ(v, w);  // i.e. |w-v|^2 -  avoid a sqrt
    if (l2 == 0.0) return ccpDistanceSQ(p, v);   // v == w case
                                                 // Consider the line extending the segment, parameterized as v + t (w - v).
                                                 // We find projection of point p onto the line.
                                                 // It falls where t = [(p-v) . (w-v)] / |w-v|^2
    const float t = ccpDot(ccpSub(p, v), ccpSub(w, v)) / l2;
    if (t < 0.0) return ccpDistanceSQ(p, v);       // Beyond the 'v' end of the segment
    else if (t > 1.0) return ccpDistanceSQ(p, w);  // Beyond the 'w' end of the segment
    const CGPoint projection = ccpAdd(v, ccpMult(ccpSub(w, v), t));  // Projection falls on the segment
    return ccpDistanceSQ(p, projection);
}
