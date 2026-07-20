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
	-- Dynamically check where it landed immediately after destruction
	local loc=c:GetLocation()
	if not (loc==LOCATION_GRAVE or loc==LOCATION_REMOVED) then return end
	
	local turn_ct = Duel.GetTurnCount()
	-- If it's already the Battle Phase or later, schedule for the next turn's Battle Phase
	if Duel.GetCurrentPhase() >= PHASE_BATTLE then
		turn_ct = turn_ct + 1
	end

	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_PHASE+PHASE_BATTLE)
	e1:SetCountLimit(1)
	e1:SetLabel(loc, turn_ct) -- Pass both the exact location and target turn count
	e1:SetLabelObject(c)
	e1:SetCondition(s.revspcon)
	e1:SetOperation(s.revspop)
	e1:SetReset(RESET_PHASE+PHASE_BATTLE, turn_ct == Duel.GetTurnCount() and 1 or 2)
	Duel.RegisterEffect(e1,tp)
end

function s.revspcon(e,tp,eg,ep,ev,re,r,rp)
	local loc, turn_ct = e:GetLabel()
	return Duel.GetTurnCount() == turn_ct
end

function s.revspop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetLabelObject()
	local loc, turn_ct = e:GetLabel()
	-- Verifies it is still in the exact location it was sent to when destroyed
	if c and c:IsLocation(loc) and c:IsCanBeSpecialSummoned(e,0,tp,false,false) then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
	e:Reset()
end

--XYZ condition
function s.xyzcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()
	return bc and bc:IsRelateToBattle() and c:IsRelateToBattle()
end

--XYZ filter
function s.xyzfilter(c,mc1,mc2,tp)
	return c:IsType(TYPE_XYZ)
		and c:IsRank(7)
		and c:IsAttribute(ATTRIBUTE_FIRE)
		and c:IsRace(RACE_WARRIOR)
end

--Target
function s.xyztg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()
	if chk==0 then
		if not bc then return false end
		return Duel.IsExistingMatchingCard(s.xyzfilter,tp,LOCATION_EXTRA,0,1,nil,c,bc,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

--Operation
function s.xyzop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()
	if not (c:IsRelateToBattle() and bc and bc:IsRelateToBattle()) then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.xyzfilter,tp,LOCATION_EXTRA,0,1,1,nil,c,bc,tp)
	local sc=g:GetFirst()
	if not sc then return end

	local mg=Group.FromCards(c,bc)
	sc:SetMaterial(mg)
	Duel.Overlay(sc,mg)
	Duel.SpecialSummon(sc,SUMMON_TYPE_XYZ,tp,tp,false,false,POS_FACEUP)
	sc:CompleteProcedure()
end
