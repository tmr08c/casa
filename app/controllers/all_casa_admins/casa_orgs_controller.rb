class AllCasaAdmins::CasaOrgsController < AllCasaAdminsController

  def show
    @casa_org = CasaOrg.find(params[:id])
  end

  # GET /casa_orgs/new
  def new
    @casa_org = CasaOrg.new
  end

  # POST /casa_orgs
  # POST /casa_orgs.json
  def create
    @casa_org = CasaOrg.new

    respond_to do |format|
      if @casa_org.save
        format.html { redirect_to @casa_org, notice: "CASA organization was successfully created." }
        format.json { render :show, status: :created, location: @casa_org }
      else
        format.html { render :new }
        format.json { render json: @casa_org.errors, status: :unprocessable_entity }
      end
    end
  end

end
