--<Limit Breaker> Renara
local s,id=GetID()
function s.initial_effect(c)
	--Cannot be destroyed by battle
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e0:SetValue(1)
	c:RegisterEffect(e0)

	--If destroyed by card effect: SS itself at the start of the Battle Phase, restrict attacks
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_DESTROYED)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.revcon)
	e1:SetOperation(s.revop)
	c:RegisterEffect(e1)

	--After damage calculation, if battled: Xyz Summon 1 Rank 7 FIRE Warrior using this card + that monster
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_BATTLED)
	e2:SetCountLimit(1,id*2)
	e2:SetCondition(s.xyzcon)
	e2:SetTarget(s.xyztg)
	e2:SetOperation(s.xyzop)
	c:RegisterEffect(e2)
end

function s.revcon(e,tp,eg,ep,ev,re,r,rp)
	return r&REASON_EFFECT~=0
end

function s.revop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsLocation(LOCATION_GRAVE) then return end
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_PHASE_START+PHASE_BATTLE_START)
	e1:SetCountLimit(1)
	e1:SetLabelObject(c)
	e1:SetOperation(s.revsp)
	e1:SetReset(RESET_PHASE+PHASE_BATTLE)
	Duel.RegisterEffect(e1,tp)
end

function s.revsp(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetLabelObject()
	if c and c:IsLocation(LOCATION_GRAVE) and c:IsCanBeSpecialSummoned(e,0,tp,false,false) then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
end

--After battling
function s.xyzcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()
	return bc and bc:IsRelateToBattle()
end
function s.xyztg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()
	if chk==0 then
		return bc and Duel.IsExistingMatchingCard(s.xyzfilter,tp,LOCATION_EXTRA,0,1,nil,c,bc,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.xyzfilter(c,mc1,mc2,tp)
	return c:IsType(TYPE_XYZ) and c:IsRank(7)
		and c:IsAttribute(ATTRIBUTE_FIRE) and c:IsRace(RACE_WARRIOR)
		and Duel.GetLocationCountFromEx(tp,tp,mc1,mc2,c)>0
end
function s.xyzop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()
	if not (c:IsRelateToEffect(e) and bc and bc:IsRelateToBattle()) then return end
	local g=Duel.GetMatchingGroup(s.xyzfilter,tp,LOCATION_EXTRA,0,nil,c,bc,tp)
	if #g>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local sc=g:Select(tp,1,1,nil):GetFirst()
		if sc then
			local mg=Group.FromCards(c,bc)
			sc:SetMaterial(mg)
			Duel.Overlay(sc,mg)
			Duel.SpecialSummon(sc,SUMMON_TYPE_XYZ,tp,tp,false,false,POS_FACEUP)
			sc:CompleteProcedure()
		end
	end
end
