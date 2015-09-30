class OrdersController < ApplicationController
  before_action :authenticate_user!

  def show
    @order = Order.find_by(token: params[:id])
    @order_info = @order.info
    @order_items = @order.items
  end

  def edit
    @order = Order.find_by(token: params[:id])
    @order_items = @order.items
  end

  def create
    @order = current_user.orders.build(order_params)

    if @order.build_item_cache_from_cart(current_cart) && @order.save
      @order.caculate_total!(current_cart)
      current_cart.destroy
      redirect_to order_url(@order.token)
    else
      render 'carts/checkout'
    end
  end

  def update
    @order = Order.find_by(token: params[:id])
    @order_items = @order.items
    if @order.update_attributes(order_params)
      flash[:notice] = 'Order information updated!'
      redirect_to order_url(@order.token)
    else
      flash[:alert] = 'Order information updated failed'
      render :edit
    end
  end

  def pay_with_credit_card
    @order = Order.find_by(token: params[:id])
    @order.set_payment_with!('credit_card')
    @order.make_payment!
    redirect_to account_orders_url, notice: 'Order has been paid.'
  end

  def allpay_notify
    order = Order.find_by_token(params[:id])
    type = params[:type]

    if params[:RtnCode] == "1"
      order.set_payment_with!(type)
      order.make_payment!
    end

    render text: '1|OK', status: 200
  end

  private

  def order_params
    params.require(:order).permit(info_attributes: [:billing_name,
      :billing_address,
      :shipping_name,
      :shipping_address])
  end
end
