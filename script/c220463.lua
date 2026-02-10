--E.V.O
local s,id=GetID()
local LIMIT_BREAK_CODE=220406 -- << change to your "Limit Break!!!" card ID

function s.initial_effect(c)
	c:EnableReviveLimit()
	-- Xyz: 2+ Level 7 Warrior
	Xyz.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsRace,RACE_WARRIOR),7,2,nil,nil,99)

	-- Quick: detach 3 → rank-up using this card
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_DAMAGE)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.rucost)
	e1:SetTarget(s.rutg)
	e1:SetOperation(s.ruop)
	c:RegisterEffect(e1)

	-- End Phase: attach 1 "Limit Break!!!" from GY as material
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_PHASE+PHASE_END)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.attachtg)
	e2:SetOperation(s.attachop)
	c:RegisterEffect(e2)
end

-- ===== Rank-up filter =====

function s.xyzfilter(c,e,tp,mc)
	return c:IsRank(7)
		and c:IsType(TYPE_XYZ)
		and not c:IsSetCard(0x48) -- exclude "Number"
		and mc:IsCanBeXyzMaterial(c)
		and Duel.GetLocationCountFromEx(tp,tp,mc,c)>0
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_XYZ,tp,false,false)
end

-- detach 3
function s.rucost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,3,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,3,3,REASON_COST)
end

function s.rutg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.xyzfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,c)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.ruop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not (c:IsFaceup() and c:IsRelateToEffect(e)) then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local xc=Duel.SelectMatchingCard(tp,s.xyzfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,c):GetFirst()
	if not xc then return end

	local atk=xc:GetOriginalAttack()

	-- transfer materials
	local mg=c:GetOverlayGroup()
	if #mg>0 then Duel.Overlay(xc,mg) end

	xc:SetMaterial(Group.FromCards(c))
	Duel.Overlay(xc,Group.FromCards(c))

	if Duel.SpecialSummon(xc,SUMMON_TYPE_XYZ,tp,tp,false,false,POS_FACEUP)>0 then
		xc:CompleteProcedure()
		if atk>0 then
			Duel.Damage(tp,atk,REASON_EFFECT)
		end
	end
end

-- ===== End Phase attach =====

function s.attachfilter(c)
	return c:IsCode(LIMIT_BREAK_CODE)
end

function s.attachtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return e:GetHandler():IsType(TYPE_XYZ)
			and Duel.IsExistingMatchingCard(s.attachfilter,tp,LOCATION_GRAVE,0,1,nil)
	end
end

function s.attachop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or not c:IsFaceup() then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
	local g=Duel.SelectMatchingCard(tp,s.attachfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	if #g>0 then
		Duel.Overlay(c,g)
	end
end
