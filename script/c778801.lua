local s,id=GetID()
function s.initial_effect(c)
	-- 1: Link Summon Procedure
	Link.AddProcedure(c,aux.FilterBoolFunction(Card.IsType,TYPE_EFFECT),2,2)
	c:EnableReviveLimit()

	-- 2: Special Summon Procedure (Alternative)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_EXTRA)
	e1:SetCondition(s.sprcon)
	e1:SetTarget(s.sprtg)
	e1:SetOperation(s.sprop)
	c:RegisterEffect(e1)
end

-- Filter for Mysthich monster (Face-up or Face-down)
function s.mysthich_filter(c,tp)
	return c:IsSetCard(0xb67) and c:IsType(TYPE_MONSTER) and (c:IsFaceup() or c:IsFacedown()) and c:IsAbleToGraveAsCost()
end

-- Filter for any face-down monster on the field
function s.facedown_filter(c,tp)
	return c:IsFacedown() and c:IsAbleToGraveAsCost()
end

-- Condition for Alternative SS
function s.sprcon(e,c,tp)
	if c==nil then return true end
	local g1=Duel.GetMatchingGroup(s.mysthich_filter,tp,LOCATION_MZONE,0,nil)
	local g2=Duel.GetMatchingGroup(s.facedown_filter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,nil)
	return Duel.GetLocationCountFromEx(tp,tp,nil,c)>0 and #g1>0 and #g2>0
end

-- Target for Alternative SS
function s.sprtg(e,tp,eg,ep,ev,re,r,rp,chk,c)
	local g1=Duel.GetMatchingGroup(s.mysthich_filter,tp,LOCATION_MZONE,0,nil)
	local g2=Duel.GetMatchingGroup(s.facedown_filter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,nil)
	
	local mg=Group.CreateGroup()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local sc1=g1:SelectUnselect(mg,tp,false,true,1,1)
	if not sc1 then return false end
	mg:AddCard(sc1)
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local sc2=g2:SelectUnselect(mg,tp,false,true,1,1)
	if not sc2 then return false end
	mg:AddCard(sc2)
	
	if #mg==2 then
		-- Reveal face-down Mysthich if it was sent
		if mg:GetFirst():IsFacedown() then Duel.ConfirmCards(1-tp,mg:GetFirst()) end
		e:SetLabelObject(mg)
		return true
	end
	return false
end

-- Operation for Alternative SS
function s.sprop(e,tp,eg,ep,ev,re,r,rp,c)
	local mg=e:GetLabelObject()
	Duel.SendtoGrave(mg,REASON_COST)
end