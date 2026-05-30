local s,id=GetID()
function s.initial_effect(c)
	-- 1. Standard Link Summon
	c:EnableReviveLimit()
	Link.AddProcedure(c,aux.FilterBoolFunction(Card.IsType,TYPE_EFFECT),2,2)

	-- 2. Alternative Contact Summon (Special Summon from Extra Deck)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetRange(LOCATION_EXTRA)
	e1:SetCondition(s.sprcon)
	e1:SetTarget(s.sprtg)
	e1:SetOperation(s.sprop)
	c:RegisterEffect(e1)
end

-- Contact Summon Conditions
function s.sprcon(e,c,tp)
	if c==nil then return true end
	-- Send 1 "Mysthich" (can be face-down) + 1 face-down monster on the field
	return Duel.IsExistingMatchingCard(s.cfilter1,tp,LOCATION_MZONE,0,1,nil)
		and Duel.IsExistingMatchingCard(s.cfilter2,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil)
end

function s.cfilter1(c)
	return c:IsSetCard(0xb67) and c:IsAbleToGraveAsCost() -- Replace 0xabc with "Mysthich" setcode
end

function s.cfilter2(c)
	return c:IsFacedown() and c:IsAbleToGraveAsCost()
end

function s.sprtg(e,tp,eg,ep,ev,re,r,rp,chk,c)
	local g1=Duel.SelectMatchingCard(tp,s.cfilter1,tp,LOCATION_MZONE,0,1,1,nil)
	local g2=Duel.SelectMatchingCard(tp,s.cfilter2,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,g1:GetFirst())
	g1:Merge(g2)
	if #g1==2 then
		e:SetLabelObject(g1)
		return true
	end
	return false
end

function s.sprop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=e:GetLabelObject()
	-- Reveal face-down Mysthich if it was face-down
	local tc=g:GetFirst()
	if tc:IsFacedown() then Duel.ConfirmCards(1-tp,tc) end
	Duel.SendtoGrave(g,REASON_COST)
end