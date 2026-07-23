--<Limit Breaker> Renara
local s,id=GetID()
function s.initial_effect(c)
	--Cannot be destroyed by battle
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e0:SetValue(1)
	c:RegisterEffect(e0)

	--If destroyed by card effect: SS itself at the start of the Battle Phase
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_DESTROYED)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.revcon)
	e1:SetOperation(s.revop)
	c:RegisterEffect(e1)

	--After damage step end: Xyz Summon using this + battled monster
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_DAMAGE_STEP_END)
	e2:SetCountLimit(1,id+100)
	e2:SetCondition(s.xyzcon)
	e2:SetTarget(s.xyztg)
	e2:SetOperation(s.xyzop)
	c:RegisterEffect(e2)
end

--Revive condition
function s.revcon(e,tp,eg,ep,ev,re,r,rp)
	return r&REASON_EFFECT~=0
end

--Register Battle Phase revive
function s.revop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local loc=c:GetLocation()
	
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_PHASE+PHASE_BATTLE_START)
	e1:SetCountLimit(1)
	e1:SetLabel(loc) 
	e1:SetLabelObject(c)
	e1:SetCondition(s.revspcon)
	e1:SetOperation(s.revspop)
	-- By leaving out standard Turn/Phase Resets, this remains active until an actual Battle Phase starts
	Duel.RegisterEffect(e1,tp)
end

-- If a Battle Phase actually starts, we check if we shouldn't trigger instantly 
-- (in case it was destroyed DURING the start of the current Battle Phase)
function s.revspcon(e,tp,eg,ep,ev,re,r,rp)
	-- If it was just destroyed this exact instant at the start of a BP, wait for the next one
	return Duel.GetTurnCount() ~= e:GetHandler():GetTurnID() or Duel.GetCurrentPhase() == PHASE_BATTLE_START
end

function s.revspop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetLabelObject()
	local loc=e:GetLabel()
	
	-- Try to summon if it's still in the exact location it landed in
	if c and c:IsLocation(loc) and c:IsCanBeSpecialSummoned(e,0,tp,false,false) then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
	-- Explicitly reset/kill the field effect only after a Battle Phase has actually happened
	e:Reset()
end

--XYZ condition
function s.xyzcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()
	return bc and bc:IsRelateToBattle() and c:IsRelateToBattle()
end

--XYZ filter with legality and Extra Deck zone verification
function s.xyzfilter(c,e,tp,mg)
	return c:IsType(TYPE_XYZ)
		and c:IsRank(7)
		and c:IsAttribute(ATTRIBUTE_FIRE)
		and c:IsRace(RACE_WARRIOR)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_XYZ,tp,false,false)
end

--Target
function s.xyztg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()
	if chk==0 then
		if not bc then return false end
		local mg=Group.FromCards(c,bc)
		return Duel.IsExistingMatchingCard(s.xyzfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

--Operation
function s.xyzop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()
	if not (c:IsRelateToBattle() and bc and bc:IsRelateToBattle()) then return end

	local mg=Group.FromCards(c,bc)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.xyzfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,mg)
	local sc=g:GetFirst()
	if not sc then return end

	sc:SetMaterial(mg)
	Duel.Overlay(sc,mg)
	Duel.SpecialSummon(sc,SUMMON_TYPE_XYZ,tp,tp,false,false,POS_FACEUP)
	sc:CompleteProcedure()
end