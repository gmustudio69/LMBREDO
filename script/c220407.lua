
local s,id=GetID()
function s.initial_effect(c)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_XMATERIAL)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCondition(function(e) return e:GetHandler():IsSetCard(0xf86) end)
	e2:SetValue(s.atkvalue)
	c:RegisterEffect(e2)
end
function s.sptgfilter(c,e,tp)
	if c:IsFacedown() or not c:IsSetCard(0xf86) then return false end
	return Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,c)
end
function s.spfilter(c,e,tp,mc)
	return c:IsType(TYPE_XYZ) and c:IsSetCard(0xf86)
		and Duel.GetLocationCountFromEx(tp,tp,mc,c)>0 and c:IsAttribute(mc:GetAttribute())
		and mc:IsCanBeXyzMaterial(c,tp,REASON_EFFECT) and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_XYZ,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_MZONE) and s.sptgfilter(chkc,e,tp) end
	if chk==0 then return Duel.IsExistingTarget(s.sptgfilter,tp,LOCATION_MZONE,0,1,nil,e,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,s.sptgfilter,tp,LOCATION_MZONE,0,1,1,nil,e,tp)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not (tc:IsFaceup() and tc:IsRelateToEffect(e) and tc:IsControler(tp) and tc:IsCanBeXyzMaterial() and not tc:IsImmuneToEffect(e)) then return end
	local pg=aux.GetMustBeMaterialGroup(tp,Group.FromCards(tc),tp,nil,nil,REASON_XYZ)
	if #pg>1 or (#pg==1 and pg:GetFirst()~=tc) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sc=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,tc):GetFirst()
	if not sc then return end
	sc:SetMaterial(tc)
	Duel.Overlay(sc,tc)
	e:GetHandler():CancelToGrave()
	Duel.Overlay(sc,e:GetHandler())
	if Duel.SpecialSummonStep(sc,SUMMON_TYPE_XYZ,tp,tp,false,false,POS_FACEUP) then
			sc:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,0,2)
			sc:CompleteProcedure()
	end
	if Duel.SpecialSummonComplete()==0 then return end
	sc:CompleteProcedure()
end
function s.atkvalue(e,c)
	return e:GetHandler():GetOverlayCount()*400
end