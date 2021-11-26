local tbl = Libs.tbl
local Vec = _Require_relative(..., 'lib.DeWallua.vector-light')
local push, pop = table.insert, table.remove
-- My port of this: https://dyn4j.org/2011/11/contact-points-using-clipping/#cpg-clip

local function clip(v1, v2, nx,ny, o)
    local clips = {}
    local d1, d2 = Vec.dot(nx,ny, v1.x,v1.y) - o, Vec.dot(nx,ny, v2.x,v2.y) - o
    if d1 >= 0 then push(clips, v1) end
    if d2 >= 0 then push(clips, v2) end

    if d1 * d2 < 0 then
        local ex,ey = Vec.sub(v2.x,v2.y, v1.x,v1.y)
        local u = d1 / (d1 - d2)
        -- scale normal by parametric distance, add to v1
        ex,ey = Vec.mul(u, ex,ey)
        ex,ey = Vec.add(ex,ey, v1.x, v1.y)
        push(clips, {x=ex,y=ey})
    end
    return clips
end

local function contact(mtv)
    if mtv.colliderShape == 'none' then return false end
    local ref, ref_max, inc, cp
    local flip = 1
    local nx,ny = Vec.normalize(mtv.x,mtv.y)
    local s1, s2 = mtv.colliderShape, mtv.collidedShape
    local e1max, e1 = s1:getFeature(nx,ny)
    local e2max, e2 = s2:getFeature(-nx,-ny)
    if not e1 then return {e1max} elseif not e2 then return {e2max} end
    local e1x, e1y = Vec.sub(e1[2].x,e1[2].y,e1[1].x,e1[1].y)
    local e2x, e2y = Vec.sub(e2[2].x,e2[2].y,e2[1].x,e2[1].y)
    local e1dn = math.abs(Vec.dot(e1x,e1y, nx,ny))
    local e2dn = math.abs(Vec.dot(e2x,e2y, nx,ny))
    if e1dn <= e2dn then
        ref, inc = e1, e2
        ref_max = e1max
    else
        ref, inc = e2, e1
        ref_max = e2max
        flip = -1
    end

    local refvx, refvy = Vec.sub(ref[2].x,ref[2].y,ref[1].x,ref[1].y)
    refvx, refvy = Vec.normalize(refvx,refvy)

    -- project first vertex onto reference edge
    local o1 = Vec.dot(ref[1].x,ref[1].y, refvx,refvy)
    cp = clip(inc[1], inc[2], refvx,refvy, o1)
    if #cp < 2 then return end

    -- project second vertex onto reference edge
    local o2 = Vec.dot(ref[2].x,ref[2].y, refvx,refvy)
    cp = clip(cp[1], cp[2], -refvx, -refvy, -o2)
    if #cp < 2 then return end

    local refnx, refny = Vec.mul(flip, Vec.perpendicular(refvx, refvy))
    local max = Vec.dot(refnx,refny, ref_max.x,ref_max.y)
    -- Ensure clips are not past projection of max onto ref-edge normal
    local cp0 = Vec.dot(refnx,refny, cp[1].x,cp[1].y) - max
    local cp1 = Vec.dot(refnx,refny, cp[2].x,cp[2].y) - max
    if cp0 < 0 then
        pop(cp, 1)
    end
    if cp1 < 0 then
        pop(cp, 2)
    end

    return cp
end

return contact