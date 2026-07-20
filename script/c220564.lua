--Overheat Detonator
local s,id,o=GetID()
function s.initial_effect(c)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_FIELD)
	e0:SetCode(EFFECT_TO_GRAVE_REDIRECT)
	e0:SetRange(LOCATION_MZONE)
	e0:SetTarget(s.rmtarget)
	e0:SetTargetRange(LOCATION_ALL,LOCATION_ALL)
	e0:SetValue(LOCATION_HAND)
	c:RegisterEffect(e0)
	---------------------------------------------------
	-- Summon effect
	---------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.destg)
	e1:SetOperation(s.desop)
	c:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e2)
	
end
---------------------------------------------------
-- REPLACEMENT: destroy → add to hand
---------------------------------------------------
function s.rmtarget(e,c)
	return c:IsReason(REASON_DESTROY)
end

function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return eg:IsExists(s.repfilter,1,nil)
	end
	return true
end

function s.repval(e,c)
	return s.repfilter(c)
end
---------------------------------------------------
-- DESTROY EFFECT FILTERS
---------------------------------------------------
function s.desfilter(c)
	return c:IsSetCard(0xc25)
		or (c:IsAttribute(ATTRIBUTE_FIRE) and c:IsRace(RACE_WARRIOR) and c:IsLevel(7))
end