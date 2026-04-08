--<Limit Breaker> Fairy Mirage
local s,id=GetID()
function s.initial_effect(c)
	--Link Summon
	c:EnableReviveLimit()
	Link.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsType,TYPE_EFFECT),2,2)
	--===== SUMMON RESTRICT =====
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(s.splimit)
	c:RegisterEffect(e0)
	--===== BECOME KAZARI =====
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(EFFECT_CHANGE_CODE)
	e1:SetValue(220450)
	c:RegisterEffect(e1)

	--===== REVIVE FROM SPELL =====
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_PHASE+PHASE_STANDBY)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.spellcon)
	e2:SetTarget(s.spelltg)
	e2:SetOperation(s.spellop)
	c:RegisterEffect(e2)
	--===== QUICK EFFECT =====
	local e3=Effect.CreateEffect(c)
	e3:SetCategory(CATEGORY_TOHAND)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id+1)
	e3:SetTarget(s.qctg)
	e3:SetOperation(s.qcop)
	c:RegisterEffect(e3)

end
s.listed_names={220450,id}
--===== LINK CHECK (same attribute) =====
function s.lcheck(g,lc,sumtype,tp)
	return g:GetClassCount(Card.GetAttribute)==1
end

--===== SUMMON LIMIT =====
function s.kzfilter(c)
	return c:IsFaceup() and (c:IsCode(220450) or c:ListsCode(220450))
end

function s.splimit(e,se,sp,st)
	return Duel.IsExistingMatchingCard(s.kzfilter,sp,LOCATION_MZONE,0,1,nil)
end

--===== SPELL REVIVE =====
function s.spellcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsType(TYPE_SPELL)
end

function s.spelltg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0 end
end

function s.spellop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
end

--===== TARGET =====
function s.plfilter(c)
	return c:IsMonster() and (c:IsControler(tp) or c:IsLocation(LOCATION_GRAVE))
end

function s.qctg(e,tp,eg,ep,ev,re,r,rp,chk)
	local g1=Duel.GetMatchingGroup(aux.TRUE,tp,LOCATION_MZONE+LOCATION_GRAVE,0,nil)
	if chk==0 then
	return Duel.GetLocationCount(tp,LOCATION_SZONE)>=1
	and #g1>0
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,1-tp,LOCATION_ONFIELD)
end

--===== OPERATION =====
function s.qcop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
	local g=Duel.SelectMatchingCard(tp,Card.IsMonster,tp,LOCATION_MZONE+LOCATION_GRAVE,0,1,2,nil)

	local ct=0
	for tc in aux.Next(g) do
	if tc:IsRelateToEffect(e) then

	--move to SZONE
	if Duel.MoveToField(tc,tp,tp,LOCATION_SZONE,POS_FACEUP,true) then
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_CHANGE_TYPE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetValue(TYPE_SPELL+TYPE_CONTINUOUS)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	tc:RegisterEffect(e1)
	ct=ct+1
	end

	end
	end

	if ct>0 then
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
	local g2=Duel.SelectMatchingCard(tp,Card.IsFaceup,tp,0,LOCATION_ONFIELD,1,ct,nil)
	if #g2>0 then
	Duel.SendtoHand(g2,nil,REASON_EFFECT)
	end
	end

end