--Keeper of the Moon Gate, Veissugr
local s,id,o=GetID()
function s.initial_effect(c)
	Link.AddProcedure(c,s.linkmatfilter,2,nil)
	c:EnableReviveLimit()
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_EXTRA)
	e1:SetCondition(s.spcon)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,2))
	e2:SetCategory(CATEGORY_POSITION)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetCountLimit(1,{id,1})
	e2:SetOperation(s.posop)
	c:RegisterEffect(e2)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,3))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_DAMAGE)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_REMOVE)
	e3:SetCountLimit(1,{id,2})
	e3:SetTarget(s.sstg)
	e3:SetOperation(s.ssop)
	c:RegisterEffect(e3)
end
function s.linkmatfilter(c,lc,sumtype,tp)
	return c:IsSetCard(0x76b)
end
function s.sumlimit(c,sump,sumtype,sumpos,targetp,se)
	return c:IsCode(id)
end
function s.mystfilter(c,tp)
	return c:IsSetCard(0x76b)
		and c:IsControler(tp)
end
function s.link2filter(c,tp)
	return c:IsSetCard(0x76b)
		and c:IsType(TYPE_LINK)
		and c:GetLink()==2
		and c:IsControler(tp)
end
function s.fdfilter(c)
	return c:IsFacedown()
		and c:IsMonster()
end
function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()

	if Duel.HasFlagEffect(tp,id) then
		return false
	end

	if Duel.GetLocationCountFromEx(tp,tp,nil,c)<=0 then
		return false
	end

	local fd=Duel.IsExistingMatchingCard(
		s.fdfilter,tp,
		LOCATION_MZONE,
		LOCATION_MZONE,
		1,nil)

	local myst2=Duel.IsExistingMatchingCard(
		s.mystfilter,tp,
		LOCATION_MZONE,0,
		2,nil)

	local link2=Duel.IsExistingMatchingCard(
		s.link2filter,tp,
		LOCATION_MZONE,0,
		1,nil)

	return fd and (myst2 or link2)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp,c)

	local sg=Group.CreateGroup()

	local b1=Duel.IsExistingMatchingCard(
		s.link2filter,tp,
		LOCATION_MZONE,0,
		1,nil)

	local b2=Duel.IsExistingMatchingCard(
		s.mystfilter,tp,
		LOCATION_MZONE,0,
		2,nil)

	local op

	if b1 and b2 then
		op=Duel.SelectOption(
			tp,
			aux.Stringid(id,0), -- Link-2 route
			aux.Stringid(id,1)  -- 2 Mysthich route
		)
	elseif b1 then
		op=0
	else
		op=1
	end

	-----------------------------------------
	-- Route A : Link-2 Mysthich
	-----------------------------------------

	if op==0 then

		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)

		local g1=Duel.SelectMatchingCard(
			tp,
			s.link2filter,
			tp,
			LOCATION_MZONE,
			0,
			1,1,nil)

		sg:Merge(g1)

	-----------------------------------------
	-- Route B : 2 Mysthich
	-----------------------------------------

	else

		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)

		local g1=Duel.SelectMatchingCard(
			tp,
			s.mystfilter,
			tp,
			LOCATION_MZONE,
			0,
			2,2,nil)

		local rg=g1:Filter(Card.IsFacedown,nil)

		if #rg>0 then
			Duel.ConfirmCards(1-tp,rg)
		end

		sg:Merge(g1)
	end

	-----------------------------------------
	-- Face-down monster
	-----------------------------------------

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)

	local g2=Duel.SelectMatchingCard(
		tp,
		s.fdfilter,
		tp,
		LOCATION_MZONE,
		LOCATION_MZONE,
		1,1,nil)

	local fd=g2:GetFirst()

	if fd:IsFacedown() then
		Duel.ConfirmCards(tp,fd)
	end

	sg:Merge(g2)

	-----------------------------------------
	-- Send everything together
	-----------------------------------------

	c:SetMaterial(sg)

	Duel.SendtoGrave(
		sg,
		REASON_MATERIAL+REASON_LINK)

	Duel.RegisterFlagEffect(
		tp,
		id,
		RESET_PHASE|PHASE_END,
		0,1)
end
function s.posop(e,tp,eg,ep,ev,re,r,rp)

	local g=Duel.GetMatchingGroup(
		Card.IsCanTurnSet,
		tp,
		0,
		LOCATION_MZONE,
		nil)

	if #g>0 then
		Duel.ChangePosition(
			g,
			POS_FACEDOWN_DEFENSE)
	end
end
function s.spfilter(c,e,tp)
	return c:IsSetCard(0x76b)
		and not c:IsCode(id)
		and c:IsCanBeSpecialSummoned(
			e,0,tp,false,false)
end
function s.sstg(e,tp,eg,ep,ev,re,r,rp,chk)

	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(
				s.spfilter,tp,
				LOCATION_REMOVED,
				0,
				1,nil,e,tp)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_SPECIAL_SUMMON,
		nil,
		3,
		tp,
		LOCATION_REMOVED)
end
function s.ssop(e,tp,eg,ep,ev,re,r,rp)

	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)

	if ft<=0 then return end

	if ft>3 then
		ft=3
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)

	local g=Duel.SelectMatchingCard(
		tp,
		s.spfilter,
		tp,
		LOCATION_REMOVED,
		0,
		1,ft,
		nil,e,tp)

	if #g==0 then return end

	local atk=0

	for tc in aux.Next(g) do
		atk=atk+math.max(tc:GetAttack(),0)
	end

	if Duel.SpecialSummon(
		g,
		0,
		tp,tp,
		false,false,
		POS_FACEUP)>0 then

		Duel.Damage(
			tp,
			atk,
			REASON_EFFECT)
	end
end