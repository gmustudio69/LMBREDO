--The Phantom, Igniter of Creation
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()

	--Fusion materials
	Fusion.AddProcCode2(c,13131313,13131321,true,true)

	--Must be Special Summoned with "Deadly Sin"
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(s.splimit)
	c:RegisterEffect(e0)

	--Unaffected by other effects
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(EFFECT_IMMUNE_EFFECT)
	e1:SetValue(s.efilter)
	c:RegisterEffect(e1)

	--Cannot be Tributed
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_UNRELEASABLE_SUM)
	e2:SetValue(1)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EFFECT_UNRELEASABLE_NONSUM)
	c:RegisterEffect(e3)

	--On summon: send other monsters you control to GY
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e4:SetCode(EVENT_SPSUMMON_SUCCESS)
	e4:SetCountLimit(1,id)
	e4:SetOperation(s.tgop)
	c:RegisterEffect(e4)

	--Opponent End Phase effect
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e5:SetCode(EVENT_PHASE+PHASE_END)
	e5:SetRange(LOCATION_MZONE+LOCATION_GRAVE)
	e5:SetCountLimit(1,id+100)
	e5:SetCondition(s.retcon)
	e5:SetOperation(s.retop)
	c:RegisterEffect(e5)
end

--Only summonable by Deadly Sin
function s.splimit(e,se,sp,st)
	return se and se:GetHandler():IsCode(13131358)
end

--Unaffected by opponent effects
function s.efilter(e,te)
	return te:GetOwner()~=e:GetOwner()
end

--Send other monsters to GY
function s.tgop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=Duel.GetMatchingGroup(Card.IsMonster,tp,LOCATION_MZONE,0,c)
	if #g>0 then
		Duel.SendtoGrave(g,REASON_EFFECT)
	end
end

--Opponent End Phase condition
function s.retcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()~=tp
end

--Umbra Witch filter
function s.spfilter(c,e,tp)
	return c:IsSetCard(0x7f6) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

--MAIN EFFECT
function s.retop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	--Return to Extra Deck (from field or GY)
	if c:IsRelateToEffect(e) then
		Duel.SendtoDeck(c,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
	end

	--🔥 Destroy ALL cards on the field
	local g=Duel.GetMatchingGroup(nil,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,nil)
	if #g>0 then
		Duel.Destroy(g,REASON_EFFECT)
	end

	--🔥 Destroy BOTH players' hands (NO REVEAL)
	local hg=Duel.GetFieldGroup(tp,LOCATION_HAND,LOCATION_HAND)
	if #hg>0 then
		Duel.Destroy(hg,REASON_EFFECT)
	end

	--🔥 Skip NEXT Draw Phase for BOTH players (FINAL FIX)
	--You
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SKIP_DP)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetTargetRange(1,0)
	e1:SetReset(RESET_PHASE+PHASE_DRAW+RESET_SELF_TURN,1)
	Duel.RegisterEffect(e1,tp)

	--Opponent
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_SKIP_DP)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e2:SetTargetRange(1,0)
	e2:SetReset(RESET_PHASE+PHASE_DRAW+RESET_SELF_TURN,1)
	Duel.RegisterEffect(e2,1-tp)

	--🔥 Special Summon 1 "Umbra Witch"
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sg=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
	if #sg>0 then
		Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP)
	end
end