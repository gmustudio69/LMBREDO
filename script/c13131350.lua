local s,id=GetID()
s.listed_names={13131313}

s.INFERNAL_DEMON=0x704
s.DEMON_MASQUERADE=0xb20

function s.initial_effect(c)
	--------------------------------------------------
	-- Equip
	--------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_EQUIP)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.eqtg)
	e1:SetOperation(s.eqop)
	c:RegisterEffect(e1)

	--------------------------------------------------
	-- Fusion
	--------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id+100)
	e2:SetTarget(s.fustg)
	e2:SetOperation(s.fusop)
	c:RegisterEffect(e2)
end

--------------------------------------------------
-- EQUIP
--------------------------------------------------

function s.eqfilter(c)
	return c:IsSetCard(s.INFERNAL_DEMON)
		and c:IsType(TYPE_MONSTER)
		and not c:IsForbidden()
end

function s.eqtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
			and Duel.IsExistingMatchingCard(s.eqfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil)
	end
end

function s.eqop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
	local tc=Duel.SelectMatchingCard(tp,s.eqfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil):GetFirst()
	if not tc then return end

	if not Duel.MoveToField(tc,tp,tp,LOCATION_SZONE,POS_FACEUP,true) then return end

	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_CHANGE_TYPE)
	e1:SetValue(TYPE_EQUIP+TYPE_SPELL)
	e1:SetReset(RESETS_STANDARD)
	tc:RegisterEffect(e1)

	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_EQUIP_LIMIT)
	e2:SetValue(function(e,cc) return cc==c end)
	e2:SetReset(RESETS_STANDARD)
	tc:RegisterEffect(e2)

	Duel.Equip(tp,tc,c)
end

--------------------------------------------------
-- FUSION
--------------------------------------------------

-- Temporary name change (ONLY during chain)
function s.applyname(c)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_CHANGE_CODE)
	e1:SetValue(13131313)
	e1:SetReset(RESET_CHAIN)
	c:RegisterEffect(e1)
end

function s.matfilter(c,e)
	return c:IsCanBeFusionMaterial() and not c:IsImmuneToEffect(e)
end

function s.getmat(tp,e)
	local mg=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_MZONE,0,nil,e)
	local eg=Duel.GetMatchingGroup(function(c)
		return c:IsType(TYPE_EQUIP) and c:IsCanBeFusionMaterial()
	end,tp,LOCATION_SZONE,0,nil)
	mg:Merge(eg)
	return mg
end

function s.fusfilter(fc,mg,e,tp)
	return fc:IsSetCard(s.DEMON_MASQUERADE)
		and fc:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false)
		and fc:CheckFusionMaterial(mg,nil,tp)
end

function s.fustg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	-- 🔥 Apply temporary Bayonetta name BEFORE activation check
	s.applyname(c)

	if chk==0 then
		local mg=s.getmat(tp,e)
		return Duel.IsExistingMatchingCard(s.fusfilter,tp,LOCATION_EXTRA,0,1,nil,mg,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.fusop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	-- 🔥 Apply again for resolution
	s.applyname(c)

	local mg=s.getmat(tp,e)

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sc=Duel.SelectMatchingCard(tp,s.fusfilter,tp,LOCATION_EXTRA,0,1,1,nil,mg,e,tp):GetFirst()
	if not sc then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
	local mat=Duel.SelectFusionMaterial(tp,sc,mg,nil,tp)
	if not mat or #mat==0 then return end

	sc:SetMaterial(mat)
	Duel.SendtoGrave(mat,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)

	Duel.BreakEffect()

	if Duel.SpecialSummon(sc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)>0 then
		sc:CompleteProcedure()
	end
end