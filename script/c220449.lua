--Limit Break - Imprison
local s,id,o=GetID()
function s.initial_effect(c)
	--During the turn in which your opponent has activated a monster effect in the hand or GY, you can activate this card from your hand
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e0:SetCode(EFFECT_TRAP_ACT_IN_HAND)
	e0:SetCondition(function(e) return Duel.GetCustomActivityCount(id,1-e:GetHandlerPlayer(),ACTIVITY_CHAIN)>0 end)
	c:RegisterEffect(e0)
	Duel.AddCustomActivityCounter(id,ACTIVITY_CHAIN,s.chainfilter)
	--Target 1 monster your opponent controls; banish it, then if you have no Traps in your GY, your opponent can Special Summon 1 monster from their hand
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_CONTROL)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	e1:SetHintTiming(0,TIMING_STANDBY_PHASE|TIMING_MAIN_END|TIMINGS_CHECK_MONSTER_E)
	c:RegisterEffect(e1)
end
function s.chainfilter(re,tp,cid)
	return not ((re:IsActiveType(TYPE_SPELL) or re:IsActiveType(TYPE_TRAP) or re:IsHasType(EFFECT_TYPE_ACTIVATE)) and re:IsHasCategory(CATEGORY_SPECIAL_SUMMON)&(LOCATION_DECK|LOCATION_EXTRA)>0)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1-tp) and chkc:IsControlerCanBeChanged() end
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
	local act_from_hand_chk=e:IsHasType(EFFECT_TYPE_ACTIVATE) and e:GetHandler():IsStatus(STATUS_ACT_FROM_HAND) and 1 or 0
	e:SetLabel(act_from_hand_chk)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONTROL)
	local g=Duel.SelectTarget(tp,Card.IsAbleToChangeControler,tp,0,LOCATION_MZONE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_CONTROL,g,1,tp,0)
	Duel.SetPossibleOperationInfo(0,CATEGORY_SET,nil,1,1-tp,LOCATION_GRAVE)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local opp=1-tp
	local tc=Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) then
	   Duel.GetControl(tc,tp)
	end
	if e:IsHasType(EFFECT_TYPE_ACTIVATE) and e:GetLabel()==1 then
		local g=Duel.GetMatchingGroup(Card.IsSSetable,opp,LOCATION_GRAVE,0,nil)
			if #g>0 and Duel.SelectYesNo(1-tp,aux.Stringid(id,1)) then
				Duel.Hint(HINT_SELECTMSG,1-tp,HINTMSG_SET)
				local sg=g:Select(1-tp,1,1,nil)
				Duel.SSet(1-tp,sg)
			end
	end
end