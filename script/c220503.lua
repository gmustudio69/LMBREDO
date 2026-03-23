--<Limit Breaker> Seraphim
local s,id=GetID()
function s.initial_effect(c)

c:EnableReviveLimit()
	--Xyz Summon procedure
	Xyz.AddProcedure(c,nil,10,3,s.xyzfilter,aux.Stringid(id,0),nil,s.xyzop)
	--Send up to 3 "Limit Break" Normal Spells to GY

--On Xyz Summon → banish
local e2=Effect.CreateEffect(c)
e2:SetCategory(CATEGORY_REMOVE)
e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
e2:SetCode(EVENT_SPSUMMON_SUCCESS)
e2:SetProperty(EFFECT_FLAG_DELAY)
e2:SetCountLimit(1,id+1)
e2:SetCondition(s.rmcon)
e2:SetTarget(s.rmtg)
e2:SetOperation(s.rmop)
c:RegisterEffect(e2)

local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EFFECT_DESTROY_REPLACE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,{id,1})
	e3:SetTarget(s.reptg)
	e3:SetOperation(function(e,tp) Duel.Damage(tp,500,REASON_REPLACE) end)
	e3:SetValue(function(e,c) return s.repfilter(c,e:GetHandlerPlayer()) end)
	c:RegisterEffect(e3)
Duel.AddCustomActivityCounter(id,ACTIVITY_CHAIN,function(re) return not re:GetHandler():IsCode(220406) end)
end

function s.xyzfilter(c,tp,xyzc)
	return c:IsFaceup() and c:IsAttribute(ATTRIBUTE_LIGHT) and c:IsType(TYPE_XYZ) and (c:IsRank(7) or c:IsRank(10))
end

function s.xyzop(e,tp,chk)
	if chk==0 then return Duel.GetFlagEffect(tp,id)==0 and
		Duel.GetCustomActivityCount(id,tp,ACTIVITY_CHAIN)>0 end
	Duel.RegisterFlagEffect(tp,id,RESET_PHASE+PHASE_END,EFFECT_FLAG_OATH,1)
	return true
end


--===== On summon =====
function s.rmcon(e,tp,eg,ep,ev,re,r,rp)
return e:GetHandler():IsSummonType(SUMMON_TYPE_XYZ)
end

--Limit Breaker filter (for detach)
function s.lbfilter(c)
return c:IsFaceup() and c:IsSetCard(0xf86) and c:GetOverlayCount()>0
end

function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk)
if chk==0 then
return Duel.IsExistingMatchingCard(s.lbfilter,tp,LOCATION_MZONE,0,1,nil)
end
end

function s.rmop(e,tp,eg,ep,ev,re,r,rp)
local c=e:GetHandler()

--collect all usable materials
local g=Duel.GetMatchingGroup(s.lbfilter,tp,LOCATION_MZONE,0,nil)
local mg=Group.CreateGroup()

for tc in aux.Next(g) do
mg:Merge(tc:GetOverlayGroup())
end

if #mg==0 then return end

--select up to 3
Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
local sg=mg:Select(tp,1,math.min(3,#mg),nil)

local ct=#sg
if ct==0 then return end

--detach selected
for tc in aux.Next(sg) do
Duel.SendtoGrave(tc,REASON_COST)
end

--banish targets
local g2=Duel.GetMatchingGroup(aux.TRUE,tp,0,LOCATION_ONFIELD+LOCATION_GRAVE,nil)
if #g2==0 then return end

Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
local rg=g2:Select(tp,1,math.min(ct,#g2),nil)
Duel.Remove(rg,POS_FACEUP,REASON_EFFECT)
end

function s.repfilter(c,tp)
	return c:IsLocation(LOCATION_ONFIELD) and c:IsControler(tp) and c:IsFaceup() and c:IsReason(REASON_EFFECT) and not c:IsReason(REASON_REPLACE)
end
function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return eg:IsExists(s.repfilter,1,nil,tp) end
	return Duel.SelectEffectYesNo(tp,c,96)
end
